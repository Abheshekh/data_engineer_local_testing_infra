# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG OWNER=jupyter
ARG BASE_CONTAINER=$OWNER/scipy-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Spark dependencies
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
ARG spark_version="3.4.0"
ARG hadoop_version="3"
ARG openjdk_version="17"
ARG scala_version="2.12.10"

ENV APACHE_SPARK_VERSION="${spark_version}" \
    HADOOP_VERSION="${hadoop_version}" \
    SCALA_VERSION="${scala_version}"

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java awscli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Spark installation
WORKDIR /tmp
RUN wget -q --no-check-certificate "https://archive.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && tar xzf "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -C /usr/local --owner root --group root --no-same-owner && \
    rm "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"

RUN wget -q "https://www.scala-lang.org/files/archive/scala-$SCALA_VERSION.tgz" && \
  tar xzf scala-$SCALA_VERSION.tgz -C /tmp/ && \
  mkdir /usr/local/scala-$SCALA_VERSION && \
  mv /tmp/scala-$SCALA_VERSION/* /usr/local/scala-$SCALA_VERSION && \
  rm -rf scala-$SCALA_VERSION.tgz 
ENV SCALA_HOME=/usr/local/scala-$SCALA_VERSION/bin

WORKDIR /usr/local

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin"

RUN ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" spark && \
    # Add a link in the before_notebook hook in order to source automatically PYTHONPATH
    mkdir -p /usr/local/bin/before-notebook.d && \
    ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Configure IPython system-wide
RUN mkdir -p /etc/ipython/ && \
    fix-permissions "/etc/ipython/"

# Download required JARs from Maven Central
WORKDIR /tmp
RUN curl -L -o aws-java-sdk-bundle-1.12.565.jar "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.565/aws-java-sdk-bundle-1.12.565.jar" && \
    curl -L -o hadoop-aws-3.3.4.jar "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar" && \
    curl -L -o mongo-spark-connector_2.12-3.0.1.jar "https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector_2.12/3.0.1/mongo-spark-connector_2.12-3.0.1.jar" && \
    curl -L -o mongo-java-driver-3.12.14.jar "https://repo1.maven.org/maven2/org/mongodb/mongo-java-driver/3.12.14/mongo-java-driver-3.12.14.jar" && \
    mv *.jar /usr/local/spark/jars/ && \
    rm -f *.jar

    # Download Delta Lake JARs (compatible with Spark 3.5.2 and Scala 2.12)
RUN curl -L -o delta-core_2.12-2.4.0.jar "https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.4.0/delta-core_2.12-2.4.0.jar" && \
curl -L -o delta-storage-2.4.0.jar "https://repo1.maven.org/maven2/io/delta/delta-storage/2.4.0/delta-storage-2.4.0.jar" && \
mv *.jar /usr/local/spark/jars/ && \
rm -f *.jar

# Download required JARs directly from Maven Central using curl
# RUN curl -o /opt/spark/jars/hadoop-aws-3.2.0.jar \
#     https://repo.maven.apache.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar \
#     && curl -o /opt/spark/jars/aws-java-sdk-bundle-1.11.375.jar \
#     https://repo.maven.apache.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.375/aws-java-sdk-bundle-1.11.375.jar \
#     && curl -o /opt/spark/jars/hadoop-common-3.2.0.jar \
#     https://repo.maven.apache.org/maven2/org/apache/hadoop/hadoop-common/3.2.0/hadoop-common-3.2.0.jar


# Python packages installation
COPY requirements.txt "/tmp/"
RUN pip install -r /tmp/requirements.txt

USER ${NB_UID}

# Install pyarrow via pip
RUN pip install pyarrow

WORKDIR "${HOME}"
