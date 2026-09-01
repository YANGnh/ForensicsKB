---
title: "K8s 集群取证命令速查"
type: technique
category: "服务器云"
competition: ""
year: ""
stage: ""
mode: ""
tags: [K8s, kubectl, 云原生, 服务器取证]
images: 0
status: "完整"
source: "原创"
created: 0000-00-00
updated: 2026-09-01
summary: "K8s 集群取证 kubectl 命令速查：查看 Pod/Service 详情与端口映射"
---
# K8s 集群取证命令速查

```sh
//查看所有pod
kubectl get pod -o wide

//查看某个pod
kubectl describe pod pod-name

//查看Pod的端口映射
kubectl get pod <pod-name> -o yaml

//查看所有service
kubectl get service -o wide

//查看Service的端口映射
kubectl get service <service-name> -o yaml
```