import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.llm_service import llm_service

word = "jurisprudence"
print(f"Testing definition generation for: '{word}'")
result = llm_service.generate_word_definition(word)
print(f"Result: {result}")
