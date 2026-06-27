import {
  BaseEntity,
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm'

import { AccessTokenEntity } from './access-token.entity'

@Entity('user_refresh_tokens')
export class RefreshTokenEntity extends BaseEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string

  @Column({ length: 500, default: '' })
  value!: string

  @Column({ comment: '令牌过期时间', nullable: true })
  expired_at!: Date

  @CreateDateColumn({ comment: '令牌创建时间' })
  created_at!: Date

  @OneToOne(() => AccessTokenEntity, accessToken => accessToken.refreshToken, {
    onDelete: 'CASCADE',
  })
  @JoinColumn()
  accessToken!: AccessTokenEntity
}
