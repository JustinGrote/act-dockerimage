# act-dockerimage

This is a simple minimal image for a Github Actions runner simulation with node, pwsh, and (optionally) dotnet

While originally developed for `act`, I primarly use it with Runner.Server these days:
https://github.com/ChristopherHX/runner.server

To use the image, simply create a `.actrc` file in your repository and add the following lines:
```
-P ubuntu-20.04=ghcr.io/justingrote/act-pwsh-dotnet:latest
-P ubuntu-latest=ghcr.io/justingrote/act-pwsh-dotnet:latest
```
