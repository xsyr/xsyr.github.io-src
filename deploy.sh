#!/bin/bash

jekyll clean
jekyll b
git commit -am 'update'
git push
