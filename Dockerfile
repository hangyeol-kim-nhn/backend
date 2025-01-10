# 1단계: 빌드를 위한 Ubuntu 기반의 JDK 21 환경 구성
FROM ubuntu:jammy AS build

# 작업 디렉토리 설정
WORKDIR /app

# 필요 패키지 설치
RUN apt-get update && \
    apt-get install -y wget curl unzip && \
    rm -rf /var/lib/apt/lists/*

# JDK 21 설치 (빌드 환경에 JDK 21.0.4+7 사용)
RUN wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz && \
    tar -xzf OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz && \
    mkdir -p /usr/lib/jvm && \
    mv jdk-21.0.4+7 /usr/lib/jvm/java-21-openjdk && \
    rm OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz

# 환경 변수 설정 (빌드용 JDK 21)
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH="$JAVA_HOME/bin:$PATH"

# Gradle 수동 설치
RUN wget https://services.gradle.org/distributions/gradle-8.3-bin.zip && \
    unzip gradle-8.3-bin.zip && \
    mv gradle-8.3 /opt/gradle && \
    rm gradle-8.3-bin.zip

# Gradle 환경 변수 설정
ENV GRADLE_HOME=/opt/gradle
ENV PATH="${GRADLE_HOME}/bin:${PATH}"

# Gradle 캐시를 활용하기 위해 Gradle 관련 파일 먼저 복사
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle

# 의존성 미리 다운로드
RUN gradle build --no-daemon || return 0

# 소스 복사
COPY src ./src

# 빌드 실행
RUN gradle clean bootJar --no-daemon

# 2단계: 실제 실행을 위한 Ubuntu:jammy 환경 사용
FROM ubuntu:jammy

# 작업 디렉토리 설정
WORKDIR /app

# 필요 패키지 설치
RUN apt-get update && \
    apt-get install -y wget curl unzip && \
    rm -rf /var/lib/apt/lists/*

# JDK 21 설치 (실행 환경에 JDK 21.0.4+7 사용)
RUN wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz && \
    tar -xzf OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz && \
    mkdir -p /usr/lib/jvm && \
    mv jdk-21.0.4+7 /usr/lib/jvm/java-21-openjdk && \
    rm OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz

# 환경 변수 설정 (실행용 JDK 21)
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH="$JAVA_HOME/bin:$PATH"

# 빌드된 JAR 파일을 복사
COPY --from=build /app/build/libs/*.jar app.jar

# 포트 설정 (Spring Boot 기본 포트)
EXPOSE 8080

# 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "app.jar"]
