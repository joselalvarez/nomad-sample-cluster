apiVersion: 1

providers:
  - name: dashboards
    type: file
    updateIntervalSeconds: 15
    options:
      path: /etc/dashboards
      foldersFromFilesStructure: true