if exists("javaScript_fold")
    syn match   javaScriptFunction      "\<function\>"
    syn region  javaScriptFunctionFold  start="\<function\>.*[^};]$" end="^\z1}.*$" transparent fold keepend

    syn sync match javaScriptSync       grouphere javaScriptFunctionFold "\<function\>"
    syn sync match javaScriptSync       grouphere NONE "^}"

    setlocal foldmethod=syntax
    setlocal foldtext=getline(v:foldstart)
else
    syn keyword javaScriptFunction      function
    syn match   javaScriptBraces           "[{}]"
endif

syn sync fromstart
syn sync maxlines=100
