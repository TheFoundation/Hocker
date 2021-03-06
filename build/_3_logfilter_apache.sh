#!/bin/bash

## Colors ;
uncolored="\033[0m" ; lightblueb="\033[1;36m" ; lightblue="\033[0;36m" ; purple="\033[0;35m" ; purpleb="\033[1;35m" ;
 black="\033[0;30m" ;  blackb="\033[1;30m"    ; white="\033[0;37m"     ; whiteb="\033[1;37m" ;    red="\033[0;31m"  ;    redb="\033[1;31m" ;
yellow="\033[0;33m" ; yellowb="\033[1;33m"    ;  blue="\033[0;34m"     ; blueb="\033[1;34m"  ;  green="\033[0;32m"  ; greenb="\033[1;93m"  ;

function black          {   echo -en "${black}${1}${uncolored}"                 ; } ;   function blackb          {   echo -en "${blackb}";cat;echo -en "${uncolored}"     ; } ;  function echo_black   {   echo -en "${black}${1}${uncolored}"              ; } ;   function echo_blackb     {   echo -en "${blackb}${1}${uncolored}"               ; } ;
function white          {   echo -en "${white}";cat;echo -en "${uncolored}"     ; } ;   function whiteb          {   echo -en "${whiteb}";cat;echo -en "${uncolored}"     ; } ;  function echo_white   {   echo -en "${white}${1}${uncolored}"              ; } ;   function echo_whiteb     {   echo -en "${whiteb}${1}${uncolored}"               ; } ;
function   red          {   echo -en "${red}";cat;echo -en "${uncolored}"       ; } ;   function   redb          {   echo -en "${redb}";cat;echo -en "${uncolored}"       ; } ;  function echo_red     {   echo -en "${red}${1}${uncolored}"                ; } ;   function echo_redb       {   echo -en "${redb}${1}${uncolored}"                 ; } ;
function green          {   echo -en "${green}";cat;echo -en "${uncolored}"     ; } ;   function greenb          {   echo -en "${greenb}";cat;echo -en "${uncolored}"     ; } ;  function yellow       {   echo -en "${yellow}";cat;echo -en "${uncolored}" ; } ;   function yellowb         {   echo -en "${yellowb}";cat;echo -en "${uncolored}"  ; } ;
function blue           {   echo -en "${blue}";cat;echo -en "${uncolored}"      ; } ;   function blueb           {   echo -en "${blueb}";cat;echo -en "${uncolored}"      ; } ;  function echo_green   {   echo -en "${green}${1}${uncolored}"              ; } ;   function echo_greenb     {   echo -en "${greenb}${1}${uncolored}"               ; } ;
function purple         {   echo -en "${purple}";cat;echo -en "${uncolored}"    ; } ;   function purpleb         {   echo -en "${purpleb}";cat;echo -en "${uncolored}"    ; } ;  function echo_yellow  {   echo -en "${yellow}${1}${uncolored}"             ; } ;   function echo_blue       {   echo -en "${blue}${1}${uncolored}"                 ; } ;
function lightblue      {   echo -en "${lightblue}";cat;echo -en "${uncolored}" ; } ;   function lightblueb      {   echo -en "${lightblueb}";cat;echo -en "${uncolored}" ; } ;  function echo_yellowb {   echo -en "${yellowb}${1}${uncolored}"            ; } ;   function echo_lightblue  {   echo -en "${lightblue}${1}${uncolored}"            ; } ;
function echo_blueb     {   echo -en "${blueb}${1}${uncolored}"                 ; } ;   function echo_purple     {   echo -en "${purple}${1}${uncolored}"                 ; } ;  function echo_purpleb {   echo -en "${purpleb}${1}${uncolored}"            ; } ;   function echo_lightblueb {   echo -en "${lightblueb}${1}${uncolored}"           ; } ;
function colors_list    {   echo_black "black";   echo_blackb "blackb";   echo_white "white";   echo_whiteb "whiteb";   echo_red "red";   echo_redb "redb";   echo_green "green";   echo_greenb "greenb";   echo_yellow "yellow";   echo_yellowb "yellowb";   echo_blue "blue";   echo_blueb "blueb";   echo_purple "purple";   echo_purpleb "purpleb";   echo_lightblue "lightblue";   echo_lightblueb "lightblueb"; } ;

#filter_web_log() {
[[ "$1" = "err" ]] && { cat | grep --line-buffered -v -e 'StatusCabot' -e ' "cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check" -e "/favicon.ico"  ; } ;
[[ "$1" = "err" ]] || { cat | grep --line-buffered -v -e 'StatusCabot' -e ' "cabot/' -e '"HEAD / HTTP/1.1" 200 - "-" "curl/' -e "UptimeRobot/" -e "docker-health-check" -e "/favicon.ico"  ; } ;
 # ; } ;
