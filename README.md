# Intro

This repository contains all images used in our CI to build [Strongbox][strongbox]. 

# Building locally

```
cd project_root
./build.sh ./images/path/to/a/Dockerfile || ./images/path/to/a/directory-containing-Dockerfiles
or 
docker build -f ./path/to/Dockerfile -t tag_name .
```

# Structure

## Base images

The `base` images are based on various distributions (i.e. `alpine:3.9`) and contain packages/tools which are commonly
used or necessary in multiple other images (i.e. jdk images or build tool images).

The files for `base` images are located in `./images/Dockerfile.*` and they should be named with the distribution they
are using (i.e. `./images/Dockerfile.alpine`).
    
Base images are tagged and published as `strongboxci/distribution_name:base`

For now we do not plan to have multi-versioned base images (i.e. multiple alpine version, multiple ubuntu versions, etc)

## JDK images

JDK images provide a specific JDK version (i.e. 8, 11, etc).
They are based on the `base` images and will inherit whatever tools are available there.

The files are located in `./images/jdk` and should be named using the distribution name and jdk version (i.e. `./images/jdk/Dockerfile.alpine.jdk8`)

JDK images are tagged and published as `strongboxci/distribution_name:jdk${VERSION}`

## Build tool images

The build tool images contain a specific build tool which is later used in the testing phase of [Strongbox][strongbox].
In most cases this image will be based on the JDK image or another `build tool` image (i.e. mvn)

The files are located in `./images/build-tools/` and should be named using the distribution name, jdk version and 
build tool name and version. The naming convention should follow the pattern below:

```
pattern: Dockerfile.__distribution_name__.__build_tool_name__
example: Dockerfile.alpine.jdk8-mvn3.6
         Dockerfile.alpine.jdk8-mvn3.6-gradle4.5
         Dockerfile.alpine.jdk8-mvn3.6-nuget
         Dockerfile.alpine.network-tools (this is not an error - the image is not based on any jdk and does not have it installed, thus the naming)
```

The build tool images are tagged and published using the same pattern as the file naming. 
In other words:
```
pattern: Dockerfile.__distribution_name__.__build_tool_name__
example: Dockerfile.alpine.jdk8-mvn3.6
         Dockerfile.alpine.jdk8-mvn3.6-gradle4.5
         Dockerfile.alpine.jdk8-mvn3.6-nuget
         Dockerfile.alpine.network-tools
```    

are tagged and pushed as

```
strongboxci/alpine:jdk8-mvn3.6
strongboxci/alpine:jdk8-mvn3.6-gradle4.5
strongboxci/alpine:jdk8-mvn3.6-nuget
strongboxci/alpine:network-tools
```

[<--# Generic links -->]: #
[strongbox]: https://github.com/strongbox/strongbox
