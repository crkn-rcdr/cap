"use strict";

const gulp = require("gulp");
const autoprefixer = require("gulp-autoprefixer");
const sass = require("gulp-sass");
sass.compiler = require("node-sass");
const purgecss = require("gulp-purgecss");
const sourcemaps = require("gulp-sourcemaps");
const cleanCSS = require("gulp-clean-css");
const concat = require("gulp-concat");
const terser = require("gulp-terser");
const { spawn } = require("child_process");

const css = () => {
  return gulp
    .src("./scss/portals/*.scss")
    .pipe(
      sass({
        includePaths: ["./node_modules/"]
      }).on("error", sass.logError)
    )
    .pipe(
      purgecss({
        content: ["../templates/**/*.tt", "../templates/**/*.html"],
        whitelistPatterns: [/tooltip/, /collapsing/],
        whitelistPatternsChildren: [/tooltip/, /collapsing/]
      })
    )
    .pipe(cleanCSS())
    .pipe(autoprefixer())
    .pipe(gulp.dest("../static/css"));
};

const cssWatch = () => {
  return gulp
    .src("./scss/portals/*.scss")
    .pipe(
      sass({
        includePaths: ["./node_modules/"]
      }).on("error", sass.logError)
    )
    .pipe(cleanCSS())
    .pipe(autoprefixer())
    .pipe(gulp.dest("../static/css"));
};

const js = () => {
  return gulp
    .src([
      "./node_modules/jquery/dist/jquery.js",
      "./node_modules/popper.js/dist/umd/popper.js",
      "./node_modules/bootstrap/dist/js/bootstrap.js",
      "./js/*.js"
    ])
    .pipe(concat("cap.js"))
    .pipe(terser())
    .pipe(gulp.dest("../static/js"));
};

const watch = () => {
  gulp.watch(
    ["./scss/**/*.scss", "../templates/**/*.tt", "../templates/**/*.html"],
    cssWatch
  );
  gulp.watch("./js/**/*.js", js);
};

exports.default = gulp.series([css, js]);
exports.watch = watch;
