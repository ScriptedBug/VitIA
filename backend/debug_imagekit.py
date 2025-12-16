import imagekitio
from imagekitio import ImageKit
import inspect

print("Inspect ImageKit:")
try:
    print(inspect.signature(ImageKit.upload_file)) # if it's a method
    print(ImageKit.upload_file.__doc__)
except Exception as e:
    print(f"Error inspecting upload_file: {e}")
    # maybe it's dynamically defined or inherited?
    print(dir(ImageKit))
