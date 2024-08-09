# **Inesdata-AI-Services**

---

`Inesdata-AI-Services` es la plataforma de desarrollo de Inteligencia Artificial basada en [Kubeflow](https://www.kubeflow.org/)

Dicha plataforma está instalada sobre un cluster de [Kubernetes](https://kubernetes.io/es/) con las siguientes características:

<center>

|         | Master (x3) | Worker (x10) |       LEN (x2)      |
|:-------:|:-----------:|:------------:|:-------------------:|
| **CPU** |      8      |      32      |          48         |
| **RAM** |      16     |      64      |         192         |
| **GPU** |      -      |      -       | 3 x 40 GB <br> 2 x 20 GB |



</center>

Para el correcto uso de la platforma, se han desarrollado las siguientes guías:

* [🛠️ Guías de instalación y administración](./guias/instalacion). Se detalla el proceso de los distintos componentes así como la configuración concreta de los mismos. También detalla cómo gestionar el acceso y alta/baja de usuarios.

* [📚 Guía de usuario](./guias/usuario). Indica cómo usar las funcionalidades de la plataforma desde un punto de vista de usuario
