---
layout: post
comments: true
title: Containerized Applications and Advantages of Them
categories: [containers]
tags: [post, blog, uppnrise, containers, technology, os, advantages]
---

Software applications are typically deployed as a single set of libraries and configuration files to a runtime environment. They are traditionally deployed to an operating system with a set of services running, such as a database server or an HTTP server, but they can also be deployed to any environment that can provide the same services, such as a virtual machine or a physical host.

The major drawback to using a software application is that it is entangled with the runtime environment and any updates or patches applied to the base OS might break the application. For example, an OS update might include multiple dependency updates, including libraries (that is, operating system libraries shared by multiple programming languages) that might affect the running application with incompatible updates.

Moreover, if another application is sharing the same host OS and the same set of libraries, as described in the next diagram, there might be a risk of breaking it if an update that fixes the first application libraries affects the second application.

Thus, for a company developing typical software applications, any maintenance on the running environment might require a full set of tests to guarantee that any OS update does not affect the application as well.

Depending on the complexity of an application, the regression verification might not be an easy task and might require a major project. Furthermore, any update normally requires a full application stop. Normally, this implies an environment with high-availability features enabled to minimize the impact of any downtime, and increases the complexity of the deployment process. The maintenance might become cumbersome, and any deployment or update might become a complex process.

![container-vs-os](https://github.com/uppnrise/uppnrise.github.io/blob/main/assets/media/container_vs_os.png?raw=true)

Alternatively, a system administrator can work with containers, which are a kind of isolated partition inside a single operating system. Containers provide many of the same benefits as virtual machines, such as security, storage, and network isolation, while requiring far fewer hardware resources and being quicker to launch and terminate. They also isolate the libraries and the runtime environment (such as CPU and storage) used by an application to minimize the impact of any OS update to the host OS, as described in the previous diagram.

Lets talk about advantages of containers.

The use of containers helps not only with the efficiency, elasticity, and reusability of the hosted applications, but also with portability of the platform and applications. There are many container providers available, such as Rocket, Drawbridge, and LXC, but one of the major providers is Docker.

Some of the major advantages of containers are listed below.

### **Low hardware footprint**
Uses OS internal features to create an isolated environment where resources are managed using OS facilities such as namespaces and cgroups. This approach minimizes the amount of CPU and memory overhead compared to a virtual machine hypervisor. Running an application in a VM is a way to create isolation from the running environment, but it requires a heavy layer of services to support the same low hardware footprint isolation provided by containers.

### **Environment isolation**
Works in a closed environment where changes made to the host OS or other applications do not affect the container. Because the libraries needed by a container are self-contained, the application can run without disruption. For example, each application can exist in its own container with its own set of libraries. An update made to one container does not affect other containers, which might not work with the update.

### **Quick deployment**
Deploys any container quickly because there is no need for a full OS install or restart. Normally, to support the isolation, a new OS installation is required on a physical host or VM, and any simple update might require a full OS restart. A container only requires a restart without stopping any services on the host OS.

### **Multiple environment deployment**
In a traditional deployment scenario using a single host, any environment differences might potentially break the application. Using containers, however, the differences and incompatibilities are mitigated because the same container image is used.

### **Reusability**
The same container can be reused by multiple applications without the need to set up a full OS. A database container can be used to create a set of tables for a software application, and it can be quickly destroyed and recreated without the need to run a set of housekeeping tasks. Additionally, the same database container can be used by the production environment to deploy an application.

Often, a software application with all its dependent services (databases, messaging, filesystems) are made to run in a single container. However, container characteristics and agility requirements might make this approach challenging or ill-advised. In these instances, a multi-container deployment may be more suitable. Additionally, be aware that some application actions may not be suited for a containerized environment. For example, applications accessing low-level hardware information, such as memory, file-systems and devices may fail due to container constraints.

Finally, containers boost the microservices development approach because they provide a lightweight and reliable environment to create and run services that can be deployed to a production or development environment without the complexity of a multiple machine environment.