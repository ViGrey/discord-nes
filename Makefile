# Copyright (C) 2018, Vi Grey
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

PKG_NAME := discord-nes
CURRENTDIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

all:
	mkdir -p $(CURRENTDIR)bin; \
	rm -rf -- $(CURRENTDIR)build/*; \
	mkdir -p $(CURRENTDIR)build/$(PKG_NAME); \
	cp -r $(CURRENTDIR)src $(CURRENTDIR)build/$(PKG_NAME); \
	cp $(CURRENTDIR)* $(CURRENTDIR)build/$(PKG_NAME); \
	cd $(CURRENTDIR)build; \
	zip -r $(PKG_NAME).zip $(PKG_NAME); \
  cd $(CURRENTDIR)src; \
  asm $(PKG_NAME).asm ../build/$(PKG_NAME).nes; \
  cd $(CURRENTDIR)build; \
	ZIPSIZE=$$(stat -L -c %s $(PKG_NAME).zip); \
	head -c $$((32778 - $$ZIPSIZE)) $(PKG_NAME).nes > new.nes; \
	cat $(PKG_NAME).zip >> new.nes; \
	zip -F new.nes --out new.zip; \
	head -c 40976 $(PKG_NAME).nes | tail -c 8198 >> new.zip; \
	mv new.zip ../bin/$(PKG_NAME).nes; \

clean:
	rm -rf -- $(CURRENTDIR)bin; \
	rm -rf -- $(CURRENTDIR)build; \
