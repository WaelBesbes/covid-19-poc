{
    apiVersion: "v1",
    kind: "Template",
    labels: {
        template: "mysql-persistent-template"
    },
    message: "The following service(s) have been created in your project: ${DATABASE_SERVICE_NAME}.\n\n       Username: ${MYSQL_USER}\n       Password: ${MYSQL_PASSWORD}\n  Database Name: ${MYSQL_DATABASE}\n Connection URL: mysql://${DATABASE_SERVICE_NAME}:3306/\n\nFor more information about using this template, including OpenShift considerations, see https://github.com/sclorg/mysql-container/blob/master/5.7/root/usr/share/container-scripts/mysql/README.md.",
    metadata: {
        annotations: {
            description: "MySQL database service, with persistent storage. For more information about using this template, including OpenShift considerations, see https://github.com/sclorg/mysql-container/blob/master/5.7/root/usr/share/container-scripts/mysql/README.md.\n\nNOTE: Scaling to more than one replica is not supported. You must have persistent volumes available in your cluster to use this template.",
            iconClass: "icon-mysql-database",
            openshift.io/display-name: "MySQL",
            openshift.io/documentation-url: "https://docs.okd.io/latest/using_images/db_images/mysql.html",
            openshift.io/long-description: "This template provides a standalone MySQL server with a database created.  The database is stored on persistent storage.  The database name, username, and password are chosen via parameters when provisioning this service.",
            openshift.io/provider-display-name: "Red Hat, Inc.",
            openshift.io/support-url: "https://access.redhat.com",
            tags: "database,mysql"
        },
        name: "mysql-persistent"
    },
    objects: [
        {
            apiVersion: "v1",
            kind: "Secret",
            metadata: {
                annotations: {
                    template.openshift.io/expose-database_name: "{.data['database-name']}",
                    template.openshift.io/expose-password: "{.data['database-password']}",
                    template.openshift.io/expose-root_password: "{.data['database-root-password']}",
                    template.openshift.io/expose-username: "{.data['database-user']}"
                },
                name: "${DATABASE_SERVICE_NAME}"
            },
            stringData: {
                database-name: "${MYSQL_DATABASE}",
                database-password: "${MYSQL_PASSWORD}",
                database-root-password: "${MYSQL_ROOT_PASSWORD}",
                database-user: "${MYSQL_USER}"
            }
        },
        {
            apiVersion: "v1",
            kind: "Service",
            metadata: {
                annotations: {
                    template.openshift.io/expose-uri: "mysql://{.spec.clusterIP}:{.spec.ports[?(.name==\"mysql\")].port}"
                },
                name: "${DATABASE_SERVICE_NAME}"
            },
            spec: {
                ports: [
                    {
                        name: "mysql",
                        port: "${{MYSQL_PORT}}"
                    }
                ],
                selector: {
                    name: "${DATABASE_SERVICE_NAME}"
                }
            }
        },
        {
            apiVersion: "v1",
            kind: "PersistentVolumeClaim",
            metadata: {
                name: "${DATABASE_SERVICE_NAME}"
            },
            spec: {
                accessModes: [
                    "ReadWriteOnce"
                ],
                resources: {
                    requests: {
                        storage: "${VOLUME_CAPACITY}"
                    }
                }
            }
        },
        {
            apiVersion: "v1",
            kind: "DeploymentConfig",
            metadata: {
                annotations: {
                    template.alpha.openshift.io/wait-for-ready: "true"
                },
                name: "${DATABASE_SERVICE_NAME}"
            },
            spec: {
                replicas: 1,
                selector: {
                    name: "${DATABASE_SERVICE_NAME}"
                },
                strategy: {
                    type: "Recreate"
                },
                template: {
                    metadata: {
                        labels: {
                            name: "${DATABASE_SERVICE_NAME}"
                        }
                    },
                    spec: {
                        containers: [
                            {
                                env: [
                                    {
                                        name: "MYSQL_USER",
                                        valueFrom: {
                                            secretKeyRef: {
                                                key: "database-user",
                                                name: "${DATABASE_SERVICE_NAME}"
                                            }
                                        }
                                    },
                                    {
                                        name: "MYSQL_PASSWORD",
                                        valueFrom: {
                                            secretKeyRef: {
                                                key: "database-password",
                                                name: "${DATABASE_SERVICE_NAME}"
                                            }
                                        }
                                    },
                                    {
                                        name: "MYSQL_ROOT_PASSWORD",
                                        valueFrom: {
                                            secretKeyRef: {
                                                key: "database-root-password",
                                                name: "${DATABASE_SERVICE_NAME}"
                                            }
                                        }
                                    },
                                    {
                                        name: "MYSQL_DATABASE",
                                        valueFrom: {
                                            secretKeyRef: {
                                                key: "database-name",
                                                name: "${DATABASE_SERVICE_NAME}"
                                            }
                                        }
                                    }
                                ],
                                image: " ",
                                imagePullPolicy: "IfNotPresent",
                                livenessProbe: {
                                    initialDelaySeconds: 30,
                                    tcpSocket: {
                                        port: "${{MYSQL_PORT}}"
                                    },
                                    timeoutSeconds: 1
                                },
                                name: "mysql",
                                ports: [
                                    {
                                        containerPort: "${{MYSQL_PORT}}"
                                    }
                                ],
                                readinessProbe: {
                                    exec: {
                                        command: [
                                            "/bin/sh",
                                            "-i",
                                            "-c",
                                            "MYSQL_PWD=\"$MYSQL_PASSWORD\" mysql -h 127.0.0.1 -u $MYSQL_USER -D $MYSQL_DATABASE -e 'SELECT 1'"
                                        ]
                                    },
                                    initialDelaySeconds: 5,
                                    timeoutSeconds: 1
                                },
                                resources: {
                                    limits: {
                                        memory: "${MEMORY_LIMIT}"
                                    }
                                },
                                volumeMounts: [
                                    {
                                        mountPath: "/var/lib/mysql/data",
                                        name: "${DATABASE_SERVICE_NAME}-data"
                                    }
                                ]
                            }
                        ],
                        volumes: [
                            {
                                name: "${DATABASE_SERVICE_NAME}-data",
                                persistentVolumeClaim: {
                                    claimName: "${DATABASE_SERVICE_NAME}"
                                }
                            }
                        ]
                    }
                },
                triggers: [
                    {
                        imageChangeParams: {
                            automatic: true,
                            containerNames: [
                                "mysql"
                            ],
                            from: {
                                kind: "ImageStreamTag",
                                name: "mysql:${MYSQL_VERSION}",
                                namespace: "${NAMESPACE}"
                            }
                        },
                        type: "ImageChange"
                    },
                    {
                        type: "ConfigChange"
                    }
                ]
            }
        }
    ],
    parameters: [
        {
            description: "Maximum amount of memory the container can use.",
            displayName: "Memory Limit",
            name: "MEMORY_LIMIT",
            required: true,
            value: "512Mi"
        },
        {
            description: "The OpenShift Namespace where the ImageStream resides.",
            displayName: "Namespace",
            name: "NAMESPACE",
            value: "openshift"
        },
        {
            description: "The name of the OpenShift Service exposed for the database.",
            displayName: "Database Service Name",
            name: "DATABASE_SERVICE_NAME",
            required: true,
            value: "mysql"
        },
        {
            description: "Username for MySQL user that will be used for accessing the database.",
            displayName: "MySQL Connection Username",
            from: "user[A-Z0-9]{3}",
            generate: "expression",
            name: "MYSQL_USER",
            required: true
        },
        {
            description: "Password for the MySQL connection user.",
            displayName: "MySQL Connection Password",
            from: "[a-zA-Z0-9]{16}",
            generate: "expression",
            name: "MYSQL_PASSWORD",
            required: true
        },
        {
            description: "Password for the MySQL root user.",
            displayName: "MySQL root user Password",
            from: "[a-zA-Z0-9]{16}",
            generate: "expression",
            name: "MYSQL_ROOT_PASSWORD",
            required: true
        },
        {
            description: "Name of the MySQL database accessed.",
            displayName: "MySQL Database Name",
            name: "MYSQL_DATABASE",
            required: true,
            value: "sampledb"
        },
        {
            description: "Volume space available for data, e.g. 512Mi, 2Gi.",
            displayName: "Volume Capacity",
            name: "VOLUME_CAPACITY",
            required: true,
            value: "1Gi"
        },
        {
            description: "Version of MySQL image to be used (5.7, or latest).",
            displayName: "Version of MySQL Image",
            name: "MYSQL_VERSION",
            required: true,
            value: "5.7"
        },
        {
            description: "Port of MySQL image to be used (5.7, or latest).",
            displayName: "Port of MySQL Image",
            name: "MYSQL_PORT",
            required: true,
            value: "3306"
        }
    ]
}