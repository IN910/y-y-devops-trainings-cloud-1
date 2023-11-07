FROM golang:1.21 as build
COPY ./catgpt /usr/src/app
WORKDIR /usr/src/app
RUN go mod download \
   && CGO_ENABLED=0 go build -o ./app_bin

FROM gcr.io/distroless/static-debian12:latest-amd64
COPY --from=build /usr/src/app /app/
EXPOSE 8080
EXPOSE 9090
CMD ["/app/app_bin"]

