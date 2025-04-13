Rollback Scenario

1. 롤백 브랜치 생성 및 checkout (Base from Master) 
2. PR Hash확인 후 해당시점으로 reset [ git reset --hard "PR Hash" ]
3. Git 원격저장소 강제 push [ git push --force ]
4. Master - 롤백 Branch diff 파일 확인
5. diff 파일들 push용 Dummy Line 생성(주석 추가), Push, Pull Request
6. Master브랜치 Merge -> 소스 반영
