import sys
from pydantic.main import ModelMetaclass

# Monkeypatch ModelMetaclass to support Python 3.14 PEP 649 (deferred annotations)
# Python 3.14 defines __annotate_func__ in the class namespace during class construction.
original_new = ModelMetaclass.__new__

def patched_new(cls, name, bases, namespace, **kwargs):
    annotate_func = namespace.get('__annotate_func__')
    if annotate_func and '__annotations__' not in namespace:
        try:
            # Evaluate class annotations (format 1 represents evaluated VALUE format)
            namespace['__annotations__'] = annotate_func(1)
        except Exception:
            pass
    return original_new(cls, name, bases, namespace, **kwargs)

ModelMetaclass.__new__ = patched_new

# Monkeypatch evaluate_forwardref to support Python 3.14 ForwardRef._evaluate signature
# Python 3.14 requires recursive_guard as a keyword-only argument.
import pydantic.typing
original_evaluate_forwardref = pydantic.typing.evaluate_forwardref

def patched_evaluate_forwardref(type_, globalns, localns):
    try:
        # Pass recursive_guard for Python 3.14
        return type_._evaluate(globalns, localns, set(), recursive_guard=set())
    except TypeError:
        # Fallback to original
        return original_evaluate_forwardref(type_, globalns, localns)

pydantic.typing.evaluate_forwardref = patched_evaluate_forwardref

print("Pydantic v1 monkeypatched successfully for Python 3.14 compatibility.")
