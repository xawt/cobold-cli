COBC     = cobc
COBFLAGS = -x
SRCS     = src/main.cob src/env-reader.cob src/context-mgr.cob \
           src/ai-caller.cob src/prompt-loader.cob
OUT      = dist/cobold

.PHONY: all clean

all: $(OUT) dist/.env dist/prompts/system-prompt.txt

$(OUT): $(SRCS)
	mkdir -p dist
	$(COBC) $(COBFLAGS) -o $(OUT) $(SRCS)

dist/.env: $(wildcard .env) .env.example
	mkdir -p dist
	cp $(if $(wildcard .env),.env,.env.example) dist/.env

dist/prompts/system-prompt.txt: prompts/system-prompt.txt
	mkdir -p dist/prompts
	cp prompts/system-prompt.txt dist/prompts/system-prompt.txt

clean:
	rm -rf dist
