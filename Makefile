# Daria HTTP-to-DNS Proxy server.

DC=dmd
NAME=daria
RELEASE_FLAGS=-O -inline -release
DEBUG_FLAGS=-debug
OUTPUT=-of$(NAME)
LIBRARIES=jlib/*/*.d
X86=-m32
FILES=*.d

all: release

release:
	@echo Building application $(NAME)...
	@$(DC) $(RELEASE_FLAGS) $(FILES) $(LIBRARIES) $(OUTPUT) && echo Done
	
debug:
	@echo Building application $(NAME) in debug mode...
	@$(DC) $(DEBUG_FLAGS) $(FILES) $(LIBRARIES) $(OUTPUT) && echo Done
	
clean:
	@rm *.o $(NAME) && echo Done
	
x86:	
	@echo Building application $(NAME) with $(X86) flag for 32-bit platform...
	@$(DC) $(RELEASE_FLAGS) $(FILES) $(LIBRARIES) $(OUTPUT) $(X86) && echo Done
	
x86_debug:	
	@echo Building application $(NAME) with $(X86) flag for 32-bit platform in debug mode...
	@$(DC) $(DEBUG_FLAGS) $(FILES) $(LIBRARIES) $(OUTPUT) $(X86) && echo Done