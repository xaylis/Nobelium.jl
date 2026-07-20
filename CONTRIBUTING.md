# Contributing to Nobelium.jl

Thanks for your interest in contributing! This document outlines the process and guidelines for contributing to Nobelium.jl.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Set up the development environment:

```julia
using Pkg
Pkg.develop(path=".")
Pkg.instantiate()
```

4. Run tests to make sure everything works:

```julia
Pkg.test("Nobelium")
```

## Development Workflow

1. Create a new branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes

3. Run tests locally:
   ```julia
   using Pkg; Pkg.test("Nobelium")
   ```

4. Match the surrounding code style (4-space indent, ~96-column lines, tight
   docstrings — read a couple of neighboring files and blend in)

5. Commit your changes with a clear message

6. Push to your fork and open a pull request

## Pull Request Guidelines

### Before Submitting

- Ensure all tests pass locally
- Add tests for new functionality
- Update documentation if needed
- Keep the style consistent with the surrounding code

### PR Requirements

- **Title**: Use a clear, descriptive title
  - Good: "Add support for forum channels"
  - Bad: "Fixed stuff"

- **Description**: Include:
  - What the PR does
  - Why the change is needed
  - Any breaking changes
  - Related issues (use "Fixes #123" or "Closes #123")

- **Size**: Keep PRs focused and reasonably sized
  - Large changes should be split into smaller, logical PRs
  - Each PR should do one thing well

- **Tests**: New features require tests, bug fixes should include regression tests

- **Documentation**: Update relevant docs for user-facing changes

### Review Process

1. A maintainer will review your PR
2. Address any requested changes
3. Once approved, a maintainer will merge your PR

## Code Style

- Follow existing code patterns in the repository
- Use descriptive variable and function names
- Add docstrings to public functions
- Keep functions focused and reasonably sized

### Naming Conventions

- Types: `PascalCase` (e.g., `GuildMember`, `VoiceState`)
- Functions: `snake_case` (e.g., `send_message`, `get_guild`)
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `API_VERSION`, `DEFAULT_INTENTS`)
- Modules: `PascalCase` (e.g., `Gateway`, `REST`)

### Documentation

Public functions should have docstrings:

```julia
"""
    send_message(client, channel_id; content, embeds, components)

Send a message to a channel.

# Arguments
- `client::Client`: The Discord client
- `channel_id::Snowflake`: Target channel ID

# Keyword Arguments
- `content::String`: Message content
- `embeds::Vector{Dict}`: Message embeds
- `components::Vector{Dict}`: Message components

# Returns
- `Message`: The created message

# Throws
- `APIError`: If the request fails
"""
function send_message(client, channel_id; kwargs...)
    # ...
end
```

## Reporting Issues

When reporting bugs, include:

- Julia version (`julia --version`)
- Nobelium.jl version
- Minimal reproducible example
- Expected vs actual behavior
- Any error messages or stack traces

## Feature Requests

For feature requests:

- Check existing issues first
- Describe the use case
- Explain why existing functionality doesn't meet your needs

## Questions

For questions about using Nobelium.jl:

- Check the documentation first
- Search existing issues
- Open a discussion or issue if you can't find an answer

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
