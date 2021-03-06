###
# Quick and dirty subtitle cleaner. Takes subtitles that have been generated by
# CCExtractor from closed captions, and compensates for the vertical scroll
# duplication. Also cleans up sentences (all-caps, etc)
#
# Cris Mihalache <cris@spectrumcoding.com>
# July 2014
# MIT License
###
_ = require "lodash"
_.str = require "underscore.string"
fs = require "fs"
parser = require "subtitles-parser"
spew = require "spew"

file = "VTS_01_1.srt"

srtRaw = fs.readFileSync "#{__dirname}/../data/#{file}", encoding: "utf-8"
srt = parser.fromSrt srtRaw, true

spew.info "Loaded #{srt.length} subtitles"

# This splits and never re-joins the lines!
cleanupText = (text) ->
  text.split("\n").map (l) ->
    l = l.trim().toLowerCase().split(".").map (sentence) ->
      _.str.capitalize sentence.trim()
    .join ". "

    # Take care of >> Name: Sentence
    if l.indexOf(">>") != -1
      processed = l.split(">> ")[1].split ": "
      processed[0] = _.str.capitalize processed[0] # Name
      processed[1] = _.str.capitalize processed[1] # Sentence
      l = ">> #{processed.join(": ")}"

    l

###
# @NOTE: We split the lines here! They need to be merged before saving
###
s.text = cleanupText s.text for s in srt

detectScroll = (lines, nextLines, dirty) ->
  if dirty
    lines[0] == nextLines[0] and lines[1] == nextLines[1]
  else
    lines[1] == nextLines[0] and lines[2] == nextLines[1]

for s, i in srt
  
  # Delete our last line, and the first line of the next subtitle
  if i < srt.length - 1
    next = srt[i + 1]

    if detectScroll s.text, next.text, !!s.dirty
      s.text.splice s.text.length - 1
      next.text.splice 0, 1
      next.dirty = true

# Join split lines
s.text = s.text.join "\n" for s in srt

fs.writeFileSync "#{__dirname}/../data/#{file}.out", parser.toSrt srt
spew.info "Wrote #{srt.length} subtitles to data/#{file}.out"
