"""
Tests for quiz endpoints:
  POST   /api/v1/quizzes/
  GET    /api/v1/quizzes/
  GET    /api/v1/quizzes/{id}
  DELETE /api/v1/quizzes/{id}
"""
from unittest.mock import patch

SAMPLE_QUIZ = {
    "title": "Python Basics",
    "total_questions": 2,
    "questions_data": [
        {
            "question": "What is Python?",
            "options": ["Language", "Snake", "Tool", "Framework"],
            "correct_answer": "Language",
        },
        {
            "question": "Which keyword defines a function?",
            "options": ["def", "fun", "func", "define"],
            "correct_answer": "def",
        },
    ],
}


# ─────────────────────────────────────────────────────────────────────────────
# Auth guards
# ─────────────────────────────────────────────────────────────────────────────


def test_create_quiz_requires_auth(client):
    assert client.post("/api/v1/quizzes/", json=SAMPLE_QUIZ).status_code == 401


def test_list_quizzes_requires_auth(client):
    assert client.get("/api/v1/quizzes/").status_code == 401


# ─────────────────────────────────────────────────────────────────────────────
# Create
# ─────────────────────────────────────────────────────────────────────────────


def test_create_quiz_success(client, auth_headers):
    resp = client.post("/api/v1/quizzes/", json=SAMPLE_QUIZ, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["title"] == SAMPLE_QUIZ["title"]
    assert data["total_questions"] == SAMPLE_QUIZ["total_questions"]
    assert len(data["questions_data"]) == 2
    assert "id" in data


def test_create_quiz_missing_title(client, auth_headers):
    bad = {k: v for k, v in SAMPLE_QUIZ.items() if k != "title"}
    assert (
        client.post("/api/v1/quizzes/", json=bad, headers=auth_headers).status_code
        == 422
    )


# ─────────────────────────────────────────────────────────────────────────────
# Generate (AI)
# ─────────────────────────────────────────────────────────────────────────────

def test_generate_quiz_success(client, auth_headers, db):
    # Create required document, vocab, and highlight manually to ensure context exists
    from app.models.document import Document
    from app.models.vocabulary import Vocabulary
    from app.models.user import User

    # The auth_headers fixture creates the user with "test@lexinote.app"
    user = db.query(User).filter(User.email == "test@lexinote.app").first()
    user_id = user.id

    doc = Document(title="Test Doc", user_id=user_id, file_path="test.pdf", original_filename="test.pdf", file_size=1024)
    db.add(doc)
    db.commit()
    db.refresh(doc)

    vocab = Vocabulary(word="test", document_id=doc.id, user_id=user_id)
    db.add(vocab)
    db.commit()

    mock_llm_response = [
        {
            "question": "What is testing?",
            "option_a": "A process",
            "option_b": "A food",
            "option_c": "A car",
            "option_d": "A dog",
            "correct_answer": "A"
        }
    ]

    with patch("app.api.v1.quiz.llm_service.generate_quiz_questions", return_value=mock_llm_response):
        resp = client.post(f"/api/v1/quizzes/generate/{doc.id}", headers=auth_headers)
        
    assert resp.status_code == 200
    data = resp.json()
    assert "Auto-generated Quiz" in data["title"]
    assert data["total_questions"] == 1
    assert data["questions_data"][0]["question"] == "What is testing?"


def test_generate_quiz_no_context(client, auth_headers, db):
    from app.models.document import Document
    from app.models.user import User
    
    # We need user_id for Document creation
    user = db.query(User).filter(User.email == "test@lexinote.app").first()
    user_id = user.id

    doc = Document(title="Empty Doc", user_id=user_id, file_path="empty.pdf", original_filename="empty.pdf", file_size=1024)
    db.add(doc)
    db.commit()
    db.refresh(doc)

    # Document has no vocab
    resp = client.post(f"/api/v1/quizzes/generate/{doc.id}", headers=auth_headers)
    assert resp.status_code == 400
    assert "No vocabulary found" in resp.json()["detail"]


# ─────────────────────────────────────────────────────────────────────────────
# List
# ─────────────────────────────────────────────────────────────────────────────


def test_list_quizzes_empty(client, auth_headers):
    resp = client.get("/api/v1/quizzes/", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


def test_list_quizzes_returns_created(client, auth_headers):
    client.post("/api/v1/quizzes/", json=SAMPLE_QUIZ, headers=auth_headers)
    client.post(
        "/api/v1/quizzes/",
        json={**SAMPLE_QUIZ, "title": "Quiz 2"},
        headers=auth_headers,
    )
    resp = client.get("/api/v1/quizzes/", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 2


def test_list_quizzes_isolated_per_user(client):
    """Each user sees only their own quizzes."""

    def login(email):
        client.post("/api/v1/users/", json={"email": email, "password": "Pass123!"})
        r = client.post(
            "/api/v1/login/access-token",
            data={"username": email, "password": "Pass123!"},
        )
        return {"Authorization": f"Bearer {r.json()['access_token']}"}

    ha = login("qa@test.com")
    hb = login("qb@test.com")

    client.post("/api/v1/quizzes/", json=SAMPLE_QUIZ, headers=ha)
    resp = client.get("/api/v1/quizzes/", headers=hb)
    assert resp.json() == []


# ─────────────────────────────────────────────────────────────────────────────
# Get single
# ─────────────────────────────────────────────────────────────────────────────


def test_get_quiz_success(client, auth_headers):
    quiz_id = client.post(
        "/api/v1/quizzes/", json=SAMPLE_QUIZ, headers=auth_headers
    ).json()["id"]
    resp = client.get(f"/api/v1/quizzes/{quiz_id}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["id"] == quiz_id


def test_get_quiz_not_found(client, auth_headers):
    assert client.get("/api/v1/quizzes/99999", headers=auth_headers).status_code == 404


# ─────────────────────────────────────────────────────────────────────────────
# Delete
# ─────────────────────────────────────────────────────────────────────────────


def test_delete_quiz_success(client, auth_headers):
    quiz_id = client.post(
        "/api/v1/quizzes/", json=SAMPLE_QUIZ, headers=auth_headers
    ).json()["id"]
    resp = client.delete(f"/api/v1/quizzes/{quiz_id}", headers=auth_headers)
    assert resp.status_code == 200
    assert (
        client.get(f"/api/v1/quizzes/{quiz_id}", headers=auth_headers).status_code
        == 404
    )


def test_delete_quiz_not_found(client, auth_headers):
    assert (
        client.delete("/api/v1/quizzes/99999", headers=auth_headers).status_code == 404
    )


def test_delete_quiz_requires_auth(client):
    assert client.delete("/api/v1/quizzes/1").status_code == 401
