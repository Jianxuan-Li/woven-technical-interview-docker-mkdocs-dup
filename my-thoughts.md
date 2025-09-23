# Some thoughts

To improve developer experience (DX) and production deployment, I have few thoughts blow:

## `serve` command for development

The command `./mkdockerize.sh serve` sounds like a command for development purpose, so should utilize the `mkdocs serve` command from container to start a dev-server, which could provide **hot-reload**. In this case document writer no need to re-run the command again to make the changes take effect.

## `serve` in production

While running in production, we could use Nginx to serve the built statics. For example:

Dockerfile

```
FROM python:3.13.7-bookworm AS builder

RUN pip install mkdocs

RUN mkdir /mkdocs-root
WORKDIR /mkdocs-root

ADD mkdocs.yml /mkdocs-root/
ADD docs /mkdocs-root/docs

RUN mkdocs build

FROM nginx:1.29.1

COPY --from=builder /mkdocs-root/site /usr/share/nginx/html

RUN ["nginx", "-g", "daemon off;"]
```

## Github action

Github action in this repo should contains different workflows:

* for normal commit on custom branch, do `test-and-build`
* for PR merge, do `prod-build`, this flow should use above production Dockerfile, then push to container registry like ECR or GHCR
