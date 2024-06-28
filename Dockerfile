FROM gradle:8.7-jdk17 as build

WORKDIR /app
COPY ./build.gradle.kts ./build.gradle.kts
COPY ./DiceApplication.java ./DiceApplication.java
COPY ./RollController.java ./RollController.java

RUN gradle assemble

FROM amazoncorretto:17-alpine
WORKDIR /app

VOLUME [ "/app" ]
VOLUME [ "/tmp" ]
ADD https://github.com/aws-observability/aws-otel-java-instrumentation/releases/download/v1.32.2/aws-opentelemetry-agent.jar /app/aws-opentelemetry-agent.jar
ENV JAVA_TOOL_OPTIONS "-javaagent:/app/aws-opentelemetry-agent.jar"

ARG JAR_FILE=build/libs/\*.jar
COPY --from=build /app/${JAR_FILE} ./app.jar

# OpenTelemetry agent configuration
ENV OTEL_TRACES_SAMPLER "always_on"
ENV OTEL_PROPAGATORS "tracecontext,baggage,xray"
ENV OTEL_RESOURCE_ATTRIBUTES "service.name=rolldice-service"
ENV OTEL_IMR_EXPORT_INTERVAL "10000"
ENV OTEL_EXPORTER_OTLP_ENDPOINT "http://localhost:4317"

ENTRYPOINT ["java","-jar","/app/app.jar"]
