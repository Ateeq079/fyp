import os
from pathlib import Path
from dotenv import load_dotenv
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import JsonOutputParser
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

# Explicitly load .env from the backend root
env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

# Support common API key env var names
raw_gemini_key = os.getenv("GEMINI_API_KEY")
if not os.getenv("GOOGLE_API_KEY") and raw_gemini_key:
    os.environ["GOOGLE_API_KEY"] = raw_gemini_key.strip('"\'')

# --- Pydantic Models ---

class GeneratedFlashcard(BaseModel):
    question: str = Field(description="A concise question")
    answer: str = Field(description="The answer to the question")

class FlashcardList(BaseModel):
    flashcards: list[GeneratedFlashcard]

class GeneratedQuestion(BaseModel):
    question: str = Field(description="The quiz question")
    option_a: str = Field(description="First answer choice")
    option_b: str = Field(description="Second answer choice")
    option_c: str = Field(description="Third answer choice")
    option_d: str = Field(description="Fourth answer choice")
    correct_answer: str = Field(description="The letter of the correct option: A, B, C, or D")

class QuestionList(BaseModel):
    questions: list[GeneratedQuestion]

class WordDefinition(BaseModel):
    definition: str = Field(description="A clear, concise definition")
    context_sentence: str = Field(description="A natural example sentence")
    related_links: list[dict] = Field(description="A list of 2-3 related links with 'title' and 'url'")

# --- Service ---

class LLMService:
    def _get_llm(self):
        google_key = os.getenv("GOOGLE_API_KEY")
        openai_key = os.getenv("OPENAI_API_KEY")
        if google_key:
            return ChatGoogleGenerativeAI(model="gemini-1.5-flash", temperature=0.2, google_api_key=google_key)
        elif openai_key:
            return ChatOpenAI(model="gpt-4o-mini", temperature=0.2, api_key=openai_key)
        raise ValueError("No API key found for LLM")

    def _get_chain(self, pydantic_object, template: str, input_vars: list[str]):
        parser = JsonOutputParser(pydantic_object=pydantic_object)
        prompt = PromptTemplate(
            template=template + "\n{format_instructions}",
            input_variables=input_vars,
            partial_variables={"format_instructions": parser.get_format_instructions()},
        )
        return prompt | self._get_llm() | parser

    def generate_flashcards(self, context_text: str) -> list[dict]:
        if not context_text.strip():
            return []
        template = """
        You are an expert tutor creating highly effective spaced-repetition flashcards.
        Given the following context, generate a set of Q&A flashcards.
        Context: {context_data}
        """
        try:
            chain = self._get_chain(FlashcardList, template, ["context_data"])
            result = chain.invoke({"context_data": context_text})
            return result.get("flashcards", [])
        except Exception as e:
            print(f"Flashcard gen error: {e}")
            return []

    def generate_quiz_questions(self, context_text: str) -> list[dict]:
        if not context_text.strip():
            return []
        template = """
        You are an expert educator creating a multiple-choice quiz.
        Rules: Exactly 4 options (A-D). correct_answer must be A, B, C, or D.
        Content: {context_data}
        """
        try:
            chain = self._get_chain(QuestionList, template, ["context_data"])
            result = chain.invoke({"context_data": context_text})
            return result.get("questions", [])
        except Exception as e:
            print(f"Quiz gen error: {e}")
            return []

    def generate_word_definition(self, word: str) -> dict | None:
        if not word.strip():
            return None
        template = """
        You are a language expert. For the word '{word}', provide a definition, 
        a context sentence, and 2-3 related links (title and url).
        """
        try:
            chain = self._get_chain(WordDefinition, template, ["word"])
            result = chain.invoke({"word": word.strip()})
            return result
        except Exception as e:
            print(f"Definition gen error for '{word}': {e}")
            return None

# Singleton instance
llm_service = LLMService()
