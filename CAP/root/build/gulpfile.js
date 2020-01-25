"use strict";

const gulp = require("gulp");
const autoprefixer = require("gulp-autoprefixer");
const sass = require("gulp-sass");
sass.compiler = require("node-sass");
const sourcemaps = require("gulp-sourcemaps");
const concat = require("gulp-concat");
const terser = require("gulp-terser");
const { spawn } = require("child_process");

const css = () => {
  return gulp
    .src("./scss/portals/*.scss")
    .pipe(sourcemaps.init())
    .pipe(
      sass({
        outputStyle: "compressed",
        includePaths: ["./node_modules/"]
      }).on("error", sass.logError)
    )
    .pipe(autoprefixer())
    .pipe(sourcemaps.write())
    .pipe(gulp.dest("../static/css"));
};

const js = () => {
  return (
    gulp
      .src([
        "./node_modules/jquery/dist/jquery.js",
        "./node_modules/popper.js/dist/umd/popper.js",
        "./node_modules/bootstrap/dist/js/bootstrap.js",
        "./js/*.js"
      ])
      .pipe(concat("cap.js"))
      // .pipe(sourcemaps.init())
      .pipe(terser())
      // .pipe(sourcemaps.write())
      .pipe(gulp.dest("../static/js"))
  );
};

const reload = done => {
  const call = spawn("docker-compose", ["exec", "cap", "kill", "-HUP", "1"], {
    cwd: "../.."
  });

  call.on("close", () => {
    done();
  });
};

const watch = () => {
  gulp.watch("./scss/**/*.scss", css);
  gulp.watch("./js/**/*.js", js);
  // gulp.watch(["../../lib/**/*", "../../conf/**/*", "../../cap.conf"], reload);
};

exports.default = gulp.series([css, js]);
exports.watch = watch;
