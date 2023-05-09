# AKS Upgrade Check List

## Introduction

The objective of this document is to provide the checks and the issues that might happen when upgrading an AKS cluster.

## 1. Infrastructure related issues

SPN issue (Akshay Nimbalkar have more details)

### 1. Issue: All cached container images are removed during upgrade.
**Solution:** No magic solution.

## 2. Networking related issues

### 1. Issue: AKS Subnet is full.
**Explanation:** During cluster upgrade, AKS will providion one or more Surge Node (or also known as Buffer) VMs and deploy pods into it. This means more IP adresses will be consumed from the cluster Subnet. Which may result in IP exhaustion issue, i.e Subnet is running out of available IPS.
**Solution:** Consider migration to a bigger Subnet range.

## 3. Kubernetes versions related issues

Kubernetes API versions might be deprecated.

With version 1.25, there is a change in managing C-Groups which results in some Java apps not working as expected. (Aymen Dhaoudi have more details)

## 4. Applications related issues
