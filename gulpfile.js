'use strict'

var gulp        = require('gulp')
  , purescript  = require('gulp-purescript')
  , runSequence = require('run-sequence')
  ;

var paths = {
    src: 'src/**/*.purs',
    bowerSrc: [
      'bower_components/purescript-*/src/**/*.purs',
      'bower_components/purescript-*/src/**/*.purs.hs'
    ],
    dest: '',
    docs: {
        'Data.Distributive': {
            dest: 'src/Data/README.md',
            src: 'src/Data/Distributive.purs'
        },
    }
};

var options = {};

var compile = function(compiler) {
    var psc = compiler(options);
    psc.on('error', function(e) {
        console.error(e.message);
        psc.end();
    });
    return gulp.src([paths.src].concat(paths.bowerSrc))
        .pipe(psc)
        .pipe(gulp.dest(paths.dest));
};

function docs (target) {
    return function() {
        return gulp.src(paths.docs[target].src)
            .pipe(purescript.docgen())
            .pipe(gulp.dest(paths.docs[target].dest));
    }
}

gulp.task('make', function() {
    return compile(purescript.pscMake);
});

gulp.task('browser', function() {
    return compile(purescript.psc);
});

gulp.task('docs-Data.Distributive', docs('Data.Distributive'));

gulp.task('docs', ['docs-Data.Distributive']);

gulp.task('watch-browser', function() {
    gulp.watch(paths.src, function() {runSequence('browser', 'docs')});
});

gulp.task('watch-make', function() {
    gulp.watch(paths.src, function() {runSequence('make', 'docs')});
});

gulp.task('default', function() {runSequence('make', 'docs')});
