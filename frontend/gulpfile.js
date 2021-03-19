"use strict";

const path = require("path");
const gulp = require("gulp");
const autoprefixer = require("gulp-autoprefixer");
const sass = require("gulp-sass");
sass.compiler = require("sass");
const purgecss = require("gulp-purgecss");
const cleanCSS = require("gulp-clean-css");
const concat = require("gulp-concat");
const terser = require("gulp-terser");

const CAP_ROOT = path.join(__dirname, "..", "CAP", "root");
const CAP_STATIC = path.join(CAP_ROOT, "static");
const TEMPLATES = ["*.tt", "*.html"].map((glob) =>
  path.posix.join(CAP_ROOT, "templates", "**", glob)
);

const css = (watch = false) =>
  function css() {
    let stream = gulp.src("./scss/portals/*.scss").pipe(
      sass({
        includePaths: ["./node_modules/bootstrap/scss"],
      }).on("error", sass.logError)
    );

    if (!watch) {
      stream = stream
        .pipe(
          purgecss({
            content: TEMPLATES,
            safelist: { deep: [/tooltip/, /collapsing/] },
          })
        )
        .pipe(cleanCSS())
        .pipe(autoprefixer());
    }

    return stream.pipe(gulp.dest(path.join(CAP_STATIC, "css")));
  };

const js = (watch = false) =>
  function js() {
    let stream = gulp
      .src([
        "./js/early/*.js",
        "./node_modules/jquery/dist/jquery.js",
        "./node_modules/popper.js/dist/umd/popper.js",
        "./node_modules/bootstrap/dist/js/bootstrap.js",
        "./js/*.js",
      ])
      .pipe(concat("cap.js"));

    if (!watch) stream = stream.pipe(terser());

    return stream.pipe(gulp.dest(path.join(CAP_STATIC, "js")));
  };

exports.default = gulp.parallel(css(false), js(false));
exports.watch = () => {
  gulp.watch(
    ["./scss/**/*.scss", ...TEMPLATES],
    { ignoreInitial: false },
    css(true)
  );
  gulp.watch("./js/**/*.js", { ignoreInitial: false }, js(true));
};
