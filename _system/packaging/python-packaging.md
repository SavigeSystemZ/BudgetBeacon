# Python Packaging Notes

- Use `python -m build` or the equivalent PEP 517 backend entrypoint.
- Produce wheels and source distributions first.
- Package Linux services with `.deb` or `.rpm` only after the Python build is reproducible.
- Keep environment files and secrets outside the package payload.
