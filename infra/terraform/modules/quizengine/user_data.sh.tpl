#! /bin/bash -ex

adduser quizengine-user
mkdir -p /opt/kmflow/quizengine

cd /opt/kmflow/quizengine
aws s3 cp s3://kmflow-org-artifacts/${release_version}.tar.gz .
tar -xf ${release_version}.tar.gz --strip-components=1

cat > /etc/systemd/system/quizcrud.service <<EOF
[Unit]
Description=Quiz CRUD Service
After=network.target

[Service]
ExecStart=/opt/kmflow/quizengine/quizcrud/quizcrud
Restart=always
User=quizengine-user
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=/opt/kmflow/quizengine

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/quizchecker.service <<EOF
[Unit]
Description=Quiz Checker Service
After=network.target

[Service]
ExecStart=/opt/kmflow/quizengine/quizchecker/quizchecker
Restart=always
User=quizengine-user
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=/opt/kmflow/quizengine

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/quizfrontend.service <<EOF
[Unit]
Description=Quiz Frontend Service
After=network.target

[Service]
ExecStart=/opt/kmflow/quizengine/quizfrontend/quizfrontend
Restart=always
User=quizengine-user
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=/opt/kmflow/quizengine

[Install]
WantedBy=multi-user.target
EOF

chown -R quizengine-user:quizengine-user /opt/kmflow/quizengine

systemctl daemon-reload
systemctl enable quizcrud
systemctl enable quizchecker
systemctl enable quizfrontend
systemctl start quizcrud
systemctl start quizchecker
systemctl start quizfrontend