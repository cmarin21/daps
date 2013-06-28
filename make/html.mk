# Copyright (C) 2012 SUSE Linux Products GmbH
#
# Author: Frank Sundermeyer
#
# HTML/HTMLSINGLE generation for DAPS
#
# Please submit feedback or patches to
# <fsundermeyer at opensuse dot org>
#

# includes are set in selector.mk
# include $(DAPSROOT)/make/setfiles.mk
# include $(DAPSROOT)/make/profiling.mk
# include $(DAPSROOT)/make/validate.mk
# include $(DAPSROOT)/make/images.mk
# include $(DAPSROOT)/make/meta.mk
#

# The code to generate HTML (not single HTML) and JSP is exactly the same,
# the only differences are:
# - the stylesheets
# - the result file
# Therefore we are making heavy use of conditionals ...
# HTML_DIR is already set in common_variables.mk
#

#----------
# Stylesheets
#
ifeq ("$(HTML5)", "yes")
  H_DIR := /xhtml5
else
  H_DIR := /xhtml
endif

ifeq ($(TARGET),jsp)
  #
  # JSP
  #
  STYLEHTML       := $(firstword $(wildcard \
			$(addsuffix /jsp/chunk.xsl,$(STYLE_ROOTDIRS))))
  HTML_SUFFIX     := jsp
  HTML_RESULT     := $(HTML_DIR)/index.jsp
else
  #
  # HTML / HTMLSINGLE
  #
  STYLEHTML       := $(firstword $(wildcard \
			$(addsuffix $(H_DIR)/chunk.xsl,$(STYLE_ROOTDIRS))))
  STYLEHTMLSINGLE := $(firstword $(wildcard \
			$(addsuffix $(H_DIR)/docbook.xsl,$(STYLE_ROOTDIRS))))
  HTML_SUFFIX     := html
  HTML_RESULT     := $(HTML_DIR)/index.html
  HTMLSINGLE_RESULT := $(HTML_DIR)/$(DOCNAME)$(DRAFT_STR)$(META_STR).html
endif


# Two scenarios:
# We either have the DocBook standard layout:
#  <STYLESHEETDIR>/images
#  <STYLESHEETDIR>/xhtml/<FOO>.css
#
# or
#
# <STYLESHEETDIR>/static
#                  |-css
#                  |-js
#                  |-images
#
# If <STYLESHEETDIR>/static exists, we use it by default. We also assume that
# parameters for [admon|callout|navig].graphics.path are correctly set in
# the stylesheets. Alternatively, a custom static directory can be specified
# with the --statdir parameter.
# 
# In case we have the standard docbook layout, we need to set
# [admon|callout|navig].graphics.path. IS_STATIC is used to determine
# whether we have a static dir (IS_STATIC=static) or not.
#
# Set the styleimage directory. If no custom directory is set with --statdir,
# it can either be <STYLEROOT>/static or <STYLEROOT>/images. If both exist,
# static will be used (firstword function)
#
ifdef STATIC_DIR
  STYLEIMG  := $(STATIC_DIR)
  IS_STATIC := static
else
  STYLEIMG := $(firstword $(wildcard \
		$(addsuffix /static,$(STYLE_ROOTDIRS)) \
		$(addsuffix /images,$(STYLE_ROOTDIRS))))
  IS_STATIC := $(notdir $(STYLEIMG))
  ifndef HTML_CSS
    ifneq ($(IS_STATIC),static)
      HTML_CSS := $(shell readlink -e $(firstword $(wildcard $(dir $(STYLEHTML))*.css)) 2>/dev/null )
      ifeq ($(VERBOSITY),1)
	HTML_CSS_INFO := No CSS file specified. Automatically using\n$(HTML_CSS)
      endif
    endif
  endif
endif

HTMLSTRINGS  += --param "show.comments=$(REMARKS)" \
                --param "use.id.as.filename=1" \
		--stringparam "base.dir=$(HTML_DIR)/" \
		--stringparam "draft.mode=$(DRAFT)" \
                --stringparam "img.src.path=images/"

# DocBook uses .xhtml for XHTML5 by default
ifeq ("$(HTML5)", "yes")
  HTMLSTRINGS  += --stringparam "html.ext=.html"
endif

# test if DocBook layout
ifneq ($(IS_STATIC),static)
  HTMLSTRINGS  += --stringparam "admon.graphics.path=static/images/" \
		  --stringparam "callout.graphics.path=static/images/callouts/" \
		  --stringparam "navig.graphics.path=static/images/"
# With the SUSE Stylesheets we use an alternative draft image for HTML
# builds (draft_html.png). The original DocBook Stylesheets use draft.png for
# _both_ HML and FO

  HTML_DRAFT_IMG = $(subst $(STYLEIMG)/,static/images/,$(firstword \
		     $(wildcard $(STYLEIMG)/draft_html.png \
		     $(STYLEIMG)/draft.png)))

  ifdef HTML_DRAFT_IMG
    HTMLSTRINGS += --stringparam "draft.watermark.image=$(HTML_DRAFT_IMG)" 
  endif
endif

ifdef HTML_CSS
  ifneq ($(HTML_CSS),none)
    HTMLSTRINGS += --stringparam "html.stylesheet=static/css/$(notdir $(HTML_CSS))"
  else
    HTML_CSS_INFO := CSS was set to none, using no CSS
    HTMLSTRINGS += --stringparam "html.stylesheet=\"\""
  endif
endif

# inline Images
#
HTML_INLINE_IMAGES := $(subst $(IMG_GENDIR)/color/,$(HTML_DIR)/images/,$(ONLINE_IMAGES))

#--------------
# HTML
#
.PHONY: html
html: list-images-multisrc list-images-missing copy_static_images
ifdef ONLINE_IMAGES
  html: $(ONLINE_IMAGES) copy_inline_images
endif
html: $(HTML_RESULT) 
	@ccecho "result" "HTML book built with REMARKS=$(REMARKS), DRAFT=$(DRAFT) and META=$(META):\n$<"

#--------------
# HTML-SINGLE
#
.PHONY: single-html
single-html: list-images-multisrc list-images-missing copy_static_images
ifdef ONLINE_IMAGES
  single-html: $(ONLINE_IMAGES) copy_inline_images
endif
single-html: $(HTMLSINGLE_RESULT)
	@ccecho "result" "SINGLE-HTML book built with REMARKS=$(REMARKS), DRAFT=$(DRAFT) and META=$(META):\n$<"

#--------------
# JSP
#
.PHONY: jsp
jsp: list-images-multisrc list-images-missing copy_static_images
ifdef ONLINE_IMAGES
  jsp: $(ONLINE_IMAGES) copy_inline_images
endif
jsp: $(HTML_RESULT) 
	@ccecho "result" "Find the JSP book at:\n$<"

#------------------------------------------------------------------------
#
# "Helper" targets for HTML and HTML-SINGLE
#

# create HTMLDIR and HTMLSIR/static:
#
$(HTML_DIR) $(HTML_DIR)/images $(HTML_DIR)/static $(HTML_DIR)/static/css:
	mkdir -p $@

# option --clean removes the contents of the HTML result directory
# before creating the files
# This target is only needed when CLEAN_DIR=1
.PHONY: clean_html
clean_html: | $(HTML_DIR)
	rm -rf $(HTML_DIR)/.[^.]* $(HTML_DIR)/*

#---------------
# Copy static and inline images
#
# static target needs to be PHONY, since I do not know which files need to
# be copied/linked, we just copy/link the whole directory
#
.PHONY: copy_static_images
ifneq ($(IS_STATIC),static)
  copy_static_images: | $(HTML_DIR)/static
    ifdef HTML_CSS
      copy_static_images: | $(HTML_DIR)/static/css
    endif
  copy_static_images: $(STYLEIMG)
    ifeq ($(STATIC_HTML), 1)
	tar cph --exclude-vcs -C $(dir $<) images | \
	  (cd $(HTML_DIR)/static; tar xpv) >/dev/null
    else
	$(HTML_GRAPH_COMMAND) $(STYLEIMG) $(HTML_DIR)/static
    endif
else
  copy_static_images: | $(HTML_DIR)/static
  copy_static_images: $(STYLEIMG)
    ifeq ($(STATIC_HTML), 1)
	tar cph --exclude-vcs -C $(dir $<) static | \
	  (cd $(HTML_DIR); tar xpv) >/dev/null
    else
	$(HTML_GRAPH_COMMAND) $</* $(HTML_DIR)/static
    endif
endif
ifdef HTML_CSS
  ifneq ($(HTML_CSS),none)
	$(HTML_GRAPH_COMMAND) $(HTML_CSS) $(HTML_DIR)/static/css/
  endif
endif

# inline images
# needs to be PHONY, because we either create links (of no --static) or
# copies of the images (with --static). Using a PHONY target ensures that
# links can be overwriotten with copies and vice versa
# Thus we also need the ugly for loop instead of creating images by 
# $(HTML_DIR)/images/% rule
#
.PHONY: copy_inline_images
copy_inline_images: | $(HTML_DIR)/images
copy_inline_images: $(ONLINE_IMAGES)
	for IMG in $(ONLINE_IMAGES); do $(HTML_GRAPH_COMMAND) $$IMG $(HTML_DIR)/images; done


#---------------
# Generate HTML or JSP from profiled xml
#
# XSLTPARAM is a variable that can be set via wrapper script in order to
# temporarily overwrite styleseet settings such as margins
#

ifeq ($(CLEAN_DIR), 1)
  $(HTML_RESULT): clean_html
endif
ifdef METASTRING
  $(HTML_DIR)/index.html: $(PROFILEDIR)/METAFILE
endif
$(HTML_RESULT): $(PROFILES) $(PROFILEDIR)/.validate $(DOCFILES)
  ifeq ($(VERBOSITY),2)
	@ccecho "info" "Creating HTML pages"
    ifdef HTML_CSS_INFO
	@ccecho "info" "$(HTML_CSS_INFO)"
    endif
  endif
	$(XSLTPROC) $(HTMLSTRINGS) $(ROOTSTRING) $(METASTRING) $(MANIFEST) \
	  $(XSLTPARAM) --xinclude --stylesheet $(STYLEHTML) \
	  --file $(PROFILED_MAIN) $(XSLTPROCESSOR) $(DEVNULL) $(ERR_DEVNULL)
  ifdef ROOTID
	if [ ! -e $@ ]; then \
	  (cd $(HTML_DIR) && ln -sf $(ROOTID).$(HTML_SUFFIX) $@) \
	fi
  endif

#---------------
# Generate HTML SINGLE from profiled xml
#
ifeq ($(CLEAN_DIR), 1)
  $(HTMLSINGLE_RESULT): clean_html
endif
ifdef METASTRING
  $(HTMLSINGLE_RESULT): $(PROFILEDIR)/METAFILE
endif
$(HTMLSINGLE_RESULT): $(DOCFILES) $(PROFILES) $(PROFILEDIR)/.validate
  ifeq ($(VERBOSITY),2)
	@ccecho "info" "   Creating single HTML page"
    ifdef HTML_CSS_INFO
	@ccecho "info" "$(HTML_CSS_INFO)"
    endif
  endif
	$(XSLTPROC) $(HTMLSTRINGS) $(ROOTSTRING) $(METASTRING) $(XSLTPARAM) \
	  --output $@ --xinclude --stylesheet $(STYLEHTMLSINGLE) \
	  --file $(PROFILED_MAIN) $(XSLTPROCESSOR) $(DEVNULL) $(ERR_DEVNULL)
	(cd $(HTML_DIR) && ln -sf $(notdir $@) index.html)

