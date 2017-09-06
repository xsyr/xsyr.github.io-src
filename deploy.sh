#!/bin/bash

jekyll clean
jekyll b
git add .
git commit -am 'update'
git push
