module.exports = function(grunt) {

  "use strict";

  grunt.initConfig({ 
  
    libFiles: [
      "src/**/*.purs",
      "bower_components/purescript-*/src/**/*.purs",
    ],
    
    clean: ["output"],
  
    pscMake: ["<%=libFiles%>"],
    dotPsci: ["<%=libFiles%>"],
    pscDocs: {
        readme: {
            src: "src/**/*.purs",
            dest: "README.md"
        }
    },
    
    jsvalidate: ["output/Data.Tuple/*.js"]

  });

  grunt.loadNpmTasks("grunt-contrib-clean");
  grunt.loadNpmTasks("grunt-purescript");
  grunt.loadNpmTasks("grunt-jsvalidate");
  
  grunt.registerTask("make", ["pscMake", "dotPsci", "pscDocs", "jsvalidate"]);
  grunt.registerTask("default", ["make"]);
};
