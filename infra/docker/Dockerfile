FROM golang:1.21.1

WORKDIR /app

# COPY ../../app/go.* .
# COPY ../../app/main.go .
# COPY ../../app/templates ./templates
# COPY ../../app/quizzes ./quizzes

COPY ../../app .

RUN pwd && cat go.mod && ls -lathr && go mod download
RUN go build -o quizengine .

EXPOSE 8080

CMD ["./quizengine"]
