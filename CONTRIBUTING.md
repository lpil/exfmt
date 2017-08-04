# Contributing

Thanks for contributing! :)

`exfmt` is an open project, contributions are very much welcomed. If you have
feedback or have found a bug, please open [an issue][issues]. If you wish to
make a code contribution please open a [pull request][prs], though for larger
code changes it may be good to open an issue first so we can work out the best
way to move forward.

[issues]: https://github.com/lpil/exfmt/issues
[prs]: https://github.com/lpil/exfmt/pulls

Please note that this project is released with a [Contributor Code of
Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to
abide by its terms.

## Setup

Currently exfmt targets the Elixir master branch as it uses features arrving
in Elixir v1.6. This can be installed either manually or using the
[asdf][asdf] version manager.

[asdf]: https://github.com/asdf-vm/asdf


```sh
# Install Elixir master using asdf
asdf install elixir master-otp-20

# Install the deps
mix deps.get
```


## Quick Reference

```sh
# Run the tests
mix test

# Run the tests when files change
mix test.watch

# Run the type checker
mix dialyzer
```
