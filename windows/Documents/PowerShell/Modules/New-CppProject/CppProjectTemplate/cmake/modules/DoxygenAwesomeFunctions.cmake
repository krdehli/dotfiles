include_guard()

#[==[.rst:
DoxygenAwesomeFunctions
-----------------------

Functions for using Doxygen Awesome with Doxygen.
#]==]

if (POLICY CMP0140)
    # return() checks its arguments
    cmake_policy(SET CMP0140 NEW)
endif()

#[==[.rst:
::

  DoxygenAwesomeFunctions_create_header_template(<doxygen_target> <out_path>)

This function generates a Doxygen header template at the provided path. The template can change
with new versions of Doxygen, so creating it with the `doxygen` command ensures compatibility across 
different versions.

.. warning::
  DoxygenAwesomeFunctions_create_header_template is used internally by DoxygenAwesomeFunctions_setup
  to create a custom HTML header for Doxygen and is not intended to be used directly. Prefer using
  DoxygenAwesomeFunctions_setup whenever possible.

Example:

.. code-block:: cmake

  DoxygenAwesomeFunctions_create_header_template(Doxygen::doxygen 
                                                 "${PROJECT_BINARY_DIR}/header.html")

This will generate a Doxygen header template file called header.html in the project
output directory.

#]==]
function(DoxygenAwesomeFunctions_create_header_template doxygen_target out_path)
    cmake_path(GET out_path FILENAME filename)
    cmake_path(GET out_path PARENT_PATH directory)

    get_target_property(DOXYGEN_COMMAND ${doxygen_target} IMPORT_LOCATION)
    execute_process(
        COMMAND ${DOXYGEN_COMMAND} -w html "${filename}" ignored.html ignored.css 
        WORKING_DIRECTORY "${directory}"
    )
    file(REMOVE 
        "${directory}/ignored.html" 
        "${directory}/ignored.css"
    )
endfunction()

#[==[.rst:
::

  DoxygenAwesomeFunctions_inject_js(<header_template_path>
                                    SCRIPTS [<script_path1> ...]
                                    CLASSES [<class_name1> ...])

Adds additional javascript files used by Doxygen Awesome extensions to the provided
Doxygen header template. Every script path added to must have an accompanying 
class name in order to initialize it.

.. warning::
  DoxygenAwesomeFunctions_inject_js is used internally by DoxygenAwesomeFunctions_setup
  to create a custom HTML header for Doxygen and is not intended to be used directly. Prefer using
  DoxygenAwesomeFunctions_setup whenever possible.

Example:

.. code-block:: cmake

  DoxygenAwesomeFunctions_inject_js("${PROJECT_BINARY_DIR}/header.html"
                                    SCRIPTS doxygen-awesome-darkmode-toggle.js
                                    CLASSES DoxygenAwesomeDarkModeToggle)

Will inject the following code into to the end of the <head> tag of the header
template:

.. code-block:: html

  <script type="text/javascript" src="$relpath^doxygen-awesome-darkmode-toggle.js"></script>
  <script type="text/javascript">
    DoxygenAwesomeDarkModeToggle.init();
  </script>
#]==]
function(DoxygenAwesomeFunctions_inject_js header_template_path)
    set(options )
    set(one_value_args )
    set(multi_value_args SCRIPTS CLASSES)
    cmake_parse_arguments("ARG"
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    set(doxygen_awesome_header_content )
    set(tag_template "<script type=\"text/javascript\" src=\"$relpath^@js_filename@\"></script>\n")
    foreach(js_file_path ${ARG_SCRIPTS})
        cmake_path(GET js_file_path FILENAME js_filename)

        string(CONFIGURE "${tag_template}" tag)
        string(APPEND doxygen_awesome_header_content "${tag}")
    endforeach()

    set(doxygen_awesome_init_script_block "<script type=\"text/javascript\">\n")
    set(init_template "\t@js_classname@.init();\n")
    foreach(js_classname ${ARG_CLASSES})
        string(CONFIGURE "${init_template}" init_statement)
        string(APPEND doxygen_awesome_init_script_block "${init_statement}")
    endforeach()
    string(APPEND doxygen_awesome_init_script_block "</script>\n")

    string(APPEND doxygen_awesome_header_content "${doxygen_awesome_init_script_block}")
    string(APPEND doxygen_awesome_header_content "</head>")

    file(READ "${header_template_path}" header_template_content)
    string(REPLACE "</head>" "${doxygen_awesome_header_content}" 
        custom_header_template_content
        "${header_template_content}"
    )
    file(WRITE "${header_template_path}" "${custom_header_template_content}")
endfunction()

#[==[.rst:
::

  DoxygenAwesomeFunctions_setup(<doxygen_awesome_source_dir>
                                [SIDEBAR_ONLY]
                                [[DOXYGEN_TARGET <doxygen_target>]
                                [DARK_MODE_TOGGLE]
                                [FRAGMENT_COPY_BUTTON]
                                [PARAGRAPH_LINKING]
                                [INTERACTIVE_TOC]])

Exports the following variables to configure doxygen to use doxygen awesome:
 - ``DOXYGEN_GENERATE_TREEVIEW``
 - ``DOXYGEN_DISABLE_INDEX``
 - ``DOXYGEN_FULL_SIDEBAR``
 - ``DOXYGEN_HTML_EXTRA_STYLESHEET``
 - ``DOXYGEN_HTML_EXTRA_FILES `
 - ``DOXYGEN_HTML_HEADER``
 - ``DOXYGEN_HTML_COLORSTYLE``
 - ``DOXYGEN_HTML_COLORSTYLE_HUE``
 - ``DOXYGEN_HTML_COLORSTYLE_SAT``
 - ``DOXYGEN_HTML_COLORSTYLE_GAMMA``
 - ``DOXYGEN_DOT_IMAGE_FORMAT``
 - ``DOXYGEN_DOT_TRANSPARENT``
#]==]
function(DoxygenAwesomeFunctions_setup doxygen_awesome_source_dir)
    set(options 
        SIDEBAR_ONLY 
        DARK_MODE_TOGGLE 
        FRAGMENT_COPY_BUTTON 
        PARAGRAPH_LINKING 
        INTERACTIVE_TOC
    )
    set(one_value_args DOXYGEN_TARGET)
    set(multi_value_args )
    cmake_parse_arguments("ARG"
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    set(DOXYGEN_GENERATE_TREEVIEW "${DOXYGEN_GENERATE_TREEVIEW}")
    set(DOXYGEN_DISABLE_INDEX NO)
    set(DOXYGEN_FULL_SIDEBAR NO)
    list(APPEND DOXYGEN_HTML_EXTRA_STYLESHEET 
        "${doxygen_awesome_source_dir}/doxygen-awesome.css"
    )
    set(DOXYGEN_HTML_EXTRA_FILES "${DOXYGEN_HTML_EXTRA_FILES}")
    set(DOXYGEN_HTML_HEADER "${DOXYGEN_HTML_HEADER}")
    set(DOXYGEN_HTML_COLORSTYLE LIGHT)
    set(DOXYGEN_HTML_COLORSTYLE_HUE 209)
    set(DOXYGEN_HTML_COLORSTYLE_SAT 255)
    set(DOXYGEN_HTML_COLORSTYLE_GAMMA 113)
    set(DOXYGEN_DOT_IMAGE_FORMAT svg)
    set(DOXYGEN_DOT_TRANSPARENT YES)

    if(ARG_SIDEBAR_ONLY)
        set(DOXYGEN_GENERATE_TREEVIEW YES)
        list(APPEND DOXYGEN_HTML_EXTRA_STYLESHEET 
            "${doxygen_awesome_source_dir}/doxygen-awesome-sidebar-only.css"
        )
    endif()

    if(ARG_DARK_MODE_TOGGLE)
        list(APPEND extension_scripts 
            "${doxygen_awesome_source_dir}/doxygen-awesome-darkmode-toggle.js"
        )
        list(APPEND extension_classes
            DoxygenAwesomeDarkModeToggle
        )
        if(ARG_SIDEBAR_ONLY)
            list(APPEND DOXYGEN_HTML_EXTRA_STYLESHEET 
                "${doxygen_awesome_source_dir}/doxygen-awesome-sidebar-only-darkmode-toggle.css"
            )
        endif()
    endif()

    if(ARG_FRAGMENT_COPY_BUTTON)
        list(APPEND extension_scripts 
            "${doxygen_awesome_source_dir}/doxygen-awesome-fragment-copy-button.js"
        )
        list(APPEND extension_classes
            DoxygenAwesomeFragmentCopyButton
        )
    endif()

    if(ARG_PARAGRAPH_LINKING)
        list(APPEND extension_scripts 
            "${doxygen_awesome_source_dir}/doxygen-awesome-paragraph-link.js"
        )
        list(APPEND extension_classes
            DoxygenAwesomeParagraphLink
        )
    endif()

    if(ARG_INTERACTIVE_TOC)
        list(APPEND extension_scripts 
            "${doxygen_awesome_source_dir}/doxygen-awesome-interactive-toc.js"
        )
        list(APPEND extension_classes
            DoxygenAwesomeInteractiveToc
        )
    endif()

    if(ARG_DARK_MODE_TOGGLE OR ARG_FRAGMENT_COPY_BUTTON OR ARG_PARAGRAPH_LINKING OR ARG_INTERACTIVE_TOC)
        if (NOT ARG_DOXYGEN_TARGET)
            message(FATAL_ERROR 
                "DOXYGEN_TARGET must be provided when using extensions in Doxygen Awesome"
            )
        endif()
        DoxygenAwesomeFunctions_create_header_template(${ARG_DOXYGEN_TARGET}
            "${CMAKE_CURRENT_BINARY_DIR}/header.html"
        )
        list(APPEND DOXYGEN_HTML_EXTRA_FILES ${extension_scripts})
        DoxygenAwesomeFunctions_inject_js("${CMAKE_CURRENT_BINARY_DIR}/header.html"
            SCRIPTS ${extension_scripts}
            CLASSES ${extension_classes}
        )
        set(DOXYGEN_HTML_HEADER "${CMAKE_CURRENT_BINARY_DIR}/header.html")
    endif()

    return(PROPAGATE
        DOXYGEN_GENERATE_TREEVIEW
        DOXYGEN_DISABLE_INDEX
        DOXYGEN_FULL_SIDEBAR
        DOXYGEN_HTML_EXTRA_STYLESHEET 
        DOXYGEN_HTML_EXTRA_FILES 
        DOXYGEN_HTML_HEADER
        DOXYGEN_HTML_COLORSTYLE
        DOXYGEN_HTML_COLORSTYLE_HUE
        DOXYGEN_HTML_COLORSTYLE_SAT
        DOXYGEN_HTML_COLORSTYLE_GAMMA
        DOXYGEN_DOT_IMAGE_FORMAT
        DOXYGEN_DOT_TRANSPARENT
    )
endfunction()