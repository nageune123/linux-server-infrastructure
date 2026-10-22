
# 08. Linux Firewall & SSH Security

## 1. 실습 목표

Ubuntu Server 24.04에서 UFW 방화벽을 구성하고, TCP 포트 접근 제어와 SSH 보안 설정을 점검한다.

## 2. 실습 환경

- VMware Workstation Pro / Ubuntu Server 24.04 LTS
- 서버 IP (Host-only): `192.168.109.128`
- 관리자 PC IP: `192.168.109.1`
- SSH 포트: TCP 22

## 3. UFW 활성화 및 SSH 허용

```bash
sudo ufw status verbose
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status numbered
```

SSH 허용 규칙을 먼저 추가한 후 UFW를 활성화하고, Windows에서 SSH 재접속을 확인했다.

## 4. HTTP 80번 포트 차단·허용 검증

테스트용 Python HTTP 서버를 실행한 상태에서 Windows PowerShell로 TCP 연결을 확인했다.

```bash
sudo python3 -m http.server 80 --bind 192.168.109.128 --directory /tmp
```

```powershell
Test-NetConnection 192.168.109.128 -Port 80
```

| UFW 설정 | TCP 연결 결과 |
|---|---|
| 80/tcp 허용 전 | False (연결 실패) |
| 80/tcp 허용 후 | True (연결 성공) |

```bash
sudo ufw allow 80/tcp
sudo ufw delete allow 80/tcp
```

실습 후 임시 허용 규칙을 삭제하고 Python HTTP 서버를 종료했다.

## 5. SSH 보안 설정 점검

```bash
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|pubkeyauthentication) '
sudo cat /etc/ssh/sshd_config.d/50-cloud-init.conf
```

| 설정 | 확인 결과 |
|---|---|
| PermitRootLogin | without-password |
| PasswordAuthentication | yes |
| PubkeyAuthentication | yes |

현재 비밀번호 기반 SSH 접속을 사용하므로, 인증 방식은 변경하지 않고 설정 상태만 점검했다.

## 6. 관리자 IP 기반 SSH 접근 제한

```bash
sudo ufw allow from 192.168.109.1 to 192.168.109.128 port 22 proto tcp
sudo ufw status numbered
```

기존 전체 IPv4 및 IPv6 SSH 허용 규칙을 순서대로 제거한 후, 관리자 IP 허용 규칙만 유지했다.

최종 허용 규칙:

```text
192.168.109.128 22/tcp  ALLOW IN  192.168.109.1
```

Windows에서 다음 명령어로 재접속을 확인했다.

```powershell
ssh -4 admin1@192.168.109.128
```

관리자 PC에서 SSH 접속 성공. 다른 출발지 IP의 차단 여부는 별도로 검증하지 않았다.

## 7. 실습 결과 및 배운 점

- UFW의 기본 인바운드 차단 정책과 포트 허용 규칙 이해
- 웹 서버가 실행 중인 상태에서 방화벽 허용 전후 TCP 연결 결과 비교
- SSH 인증 설정 및 추가 설정 파일 확인
- 관리자 IP 기반 SSH 접근 제한 구성
- 변경 후 새 SSH 연결을 통해 접근 가능 여부 검증

> 주의: 관리자 IP 또는 네트워크 구성이 변경되면 SSH 허용 규칙도 재점검해야 한다.
