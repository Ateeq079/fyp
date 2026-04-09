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
    def _get_llm(self, max_tokens: int = 1000):
        google_key = os.getenv("GOOGLE_API_KEY")
        openai_key = os.getenv("OPENAI_API_KEY")
        if google_key:
            clean_key = google_key.strip('"\' ')
            return ChatGoogleGenerativeAI(
                model="gemini-2.5-flash",  # Using 2.5 Flash for better speed/cost balance
                temperature=0.2,
                google_api_key=clean_key,
                max_output_tokens=max_tokens
            )
        elif openai_key:
            clean_key = openai_key.strip('"\' ')
            return ChatOpenAI(
                model="gpt-4o-mini",
                temperature=0.2,
                api_key=clean_key,
                max_tokens=max_tokens
            )
        raise ValueError("No API key found for LLM. Set GOOGLE_API_KEY or OPENAI_API_KEY.")

    def _get_chain(self, pydantic_object, template: str, input_vars: list[str], max_tokens: int = 1000):
        parser = JsonOutputParser(pydantic_object=pydantic_object)
        
        # Optimization: Explicitly tell the model to be concise and ONLY output JSON
        strict_template = template + "\nCRITICAL: Respond ONLY with a valid JSON object. No markdown, no intro/outro text.\n{format_instructions}"
        
        prompt = PromptTemplate(
            template=strict_template,
            input_variables=input_vars,
            partial_variables={"format_instructions": parser.get_format_instructions()},
        )
        try:
            llm = self._get_llm(max_tokens=max_tokens)
            return prompt | llm | parser
        except Exception as e:
            print(f"Error initializing LLM chain: {e}")
            raise

    def generate_flashcards(self, context_text: str) -> list[dict]:
        if not context_text.strip():
            return []
        template = """
        You are an expert tutor creating highly effective spaced-repetition flashcards based on the 'Active Recall' principle.
        
        Rules for generation:
        1. Questions must be concise and avoid giving away the answer.
        2. Answers must be direct and focused on a single concept.
        3. If the context includes specific vocabulary, focus on their usage and meaning.
        
        Context Data:
        {context_data}
        
        Generate a set of high-quality Q&A flashcards.
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
        You are an expert educator creating a multiple-choice quiz that tests deep understanding, not just surface recognition.
        
        Rules:
        1. Provide exactly 4 options (A, B, C, D).
        2. 'correct_answer' must be the single character: A, B, C, or D.
        3. Distractors (wrong options) must be plausible but clearly incorrect.
        4. Focus on critical concepts provided in the content.
        
        Content:
        {context_data}
        """
        try:
            chain = self._get_chain(QuestionList, template, ["context_data"])
            result = chain.invoke({"context_data": context_text})
            questions = result.get("questions", [])
            
            # --- Validation & Hallucination Checks ---
            validated_questions = []
            valid_letters = {"A", "B", "C", "D"}
            
            for q in questions:
                # 1. Existence check
                required_keys = ["question", "option_a", "option_b", "option_c", "option_d", "correct_answer"]
                if not all(k in q for k in required_keys):
                    continue
                
                # 2. Correct answer format
                ans = str(q.get("correct_answer", "")).upper().strip()
                if ans not in valid_letters:
                    continue
                
                # 3. Non-empty options
                options = [q["option_a"], q["option_b"], q["option_c"], q["option_d"]]
                if any(not str(opt).strip() for opt in options):
                    continue
                
                # 4. Check for duplicate options (lazy distractor generation)
                if len(set(opt.strip().lower() for opt in options)) < 4:
                    continue
                    
                # Clean up correct_answer to be consistent
                q["correct_answer"] = ans
                validated_questions.append(q)
                
            return validated_questions
        except Exception as e:
            print(f"Quiz gen error: {e}")
            return []

    def generate_word_definition(self, word: str) -> dict | None:
        if not word.strip():
            return None
        template = """
        You are a language expert. For the word '{word}', provide a professional dictionary-style definition.
        
        Requirements:
        1. definition: Simple yet precise explanation.
        2. context_sentence: A natural, high-quality sentence illustrating the word's usage.
        3. related_links: Exactly 2-3 high-authority educational or dictionary links (e.g., Cambridge, Oxford, Wikipedia).
        
        Focus on the most common academic or professional usage of the word.
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
