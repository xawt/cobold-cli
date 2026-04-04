COBC     = cobc
COBFLAGS = -x
SRCS     = src/main.cob src/env-reader.cob
OUT      = dist/cobold

.PHONY: all clean

all: $(OUT) dist/.env

$(OUT): $(SRCS)
	mkdir -p dist
	$(COBC) $(COBFLAGS) -o $(OUT) $(SRCS)

dist/.env: $(wildcard .env) .env.example
	mkdir -p dist
	cp $(if $(wildcard .env),.env,.env.example) dist/.env

clean:
	rm -rf dist
