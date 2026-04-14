function md_to_pdf
    pandoc $argv[1] -o $argv[2] -V documentclass=ltjsarticle --pdf-engine=lualatex
end
