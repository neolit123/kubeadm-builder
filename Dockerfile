FROM golang:1.11.2-stretch
COPY ./entry.sh /go
RUN chmod +x entry.sh
ENTRYPOINT ["/go/entry.sh"]
