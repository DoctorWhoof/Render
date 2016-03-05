# Render
Small rendering module for the Monkey programming language.
Requires the Vector module (or some equivalent module with Vector and Rect classes).

Features:
- Perform all rendering in a "virtual resolution" that automatically resizes to the display device
- Optionally render to a texture, ideal for accurate "pixel art" games, with or without filtering
- Scaling can maintain aspect ratio (with black bars on edges of screen)
- Optional integer scaling for maximum fidelity pixel art, at the expense of not always filling the screen
- Drawing layers with camera coordinates and parallax scrolling
- Obtain mouse coordinates in world space (offset by camera and compensated for virtual resolution scaling)

Please check the render examples repository for common usage examples.
