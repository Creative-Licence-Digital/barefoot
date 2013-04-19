{spawn, exec} = require 'child_process'
fs = require 'fs'

task "doc", "generate documentation", ->
  exec "docco -l linear barefoot.litcoffee"

task "readme", "rebuild the readme file", ->
   source = fs.readFileSync('barefoot.litcoffee').toString()
   source = source.replace /\n\n    ([\s\S]*?)\n\n(?!    )/mg, (match, code) ->
     "\n```coffeescript\n#{code.replace(/^    /mg, '')}\n```\n"
   fs.writeFileSync 'README.md', source
