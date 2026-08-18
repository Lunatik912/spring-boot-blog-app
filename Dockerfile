## this is conventional process
FROM eclipse-temurin:21-jre
VOLUME /tmp
VOLUME /X/attachments
COPY target/*.jar app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]


## spring boot supports optimized/layed docker image generation support
# use :mvn package spring-boot:build-image
