# LexiNote - Session Handoff Summary
*Date: March 6, 2026*

## 🎯 Current Project Phase
We are currently in the **Execution Phase** of developing the **PDF Reader and Dictionary** functionality. We have successfully wired up the new PDF Viewer, local annotations, and dictionary saving. 

## ✅ Accomplished in this Session

### 1. Backend (FastAPI & PostgreSQL)
*   **Database Schema Updates**: 
    *   Refactored the `Vocabulary` model to link directly to `Document` (via `document_id`) rather than going through a `Highlight` model.
    *   Added `user_id` and `created_at` fields to track personal dictionaries.
    *   Restored the `flashcards` back-population relationship in the `Highlight` model to resolve SQLAlchemy mapping errors.
*   **New API Endpoints**:
    *   `POST /vocabulary/`: Saves a selected word and its context sentence to the user's dictionary.
    *   `GET /vocabulary/` & `DELETE /vocabulary/{id}`: View and manage personal dictionary entries.
    *   `PUT /documents/{id}/file`: Replaces the existing PDF stored on the server with a newly annotated version.
*   **Tests**: Updated and passed all `pytest` suites successfully (54/54 tests passing).

### 2. Frontend (Flutter)
*   **PDF Viewer Integration**: 
    *   Added the `syncfusion_flutter_pdfviewer` (^32.2.8) and `path_provider` packages.
    *   Created `PdfViewerPage.dart`. It downloads and renders the PDF seamlessly.
*   **Context Menu & Annotations**:
    *   Implemented a floating context menu that appears upon text selection.
    *   **Highlights & Underlines**: Applied locally using Syncfusion's `HighlightAnnotation` and `UnderlineAnnotation`. Captured boundaries using `_pdfViewerKey.currentState?.getSelectedTextLines()`.
    *   **Added to Dictionary**: Sends the selected word to the backend.
*   **Saving Changes**: 
    *   Added a prompt when the user exits the PDF Viewer to ask if they want to save or discard their unsaved Highlights and Underlines.
    *   Connected this to the `replaceDocument` API endpoint to overwrite the remote file with the newly generated PDF bytes.
*   **Security & Interceptors**:
    *   Added a global `navigatorKey` in `main.dart`.
    *   Wired up `AuthService.handleUnauthorized()` across `DocumentService` and `HighlightService` to automatically trigger a logout and redirect the user back to the Login Screen gracefully when their JWT token expires (Catching `401 Unauthorized`).
    *   Resolved all static analyzer checks (`flutter analyze`).

## 🚀 Next Steps to Pick Up Later
When the next session begins, provide this prompt/summary to the AI to re-establish context. The immediate next goals are:

1.  **Frontend Verification**: The user needs to verify the dictionary API behavior using the app interface and ensure words appear in their profile.
2.  **Vocabulary Screen**: Implement the UI to list the saved vocabulary words if not already done.
3.  **Flashcards (Upcoming Phase)**: Begin planning the generation of flashcards mapping to the user's highlighted text and dictionary entries.

---
*End of Summary*
