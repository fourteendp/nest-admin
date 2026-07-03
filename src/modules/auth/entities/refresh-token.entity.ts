import {
  BaseEntity,
  BeforeInsert,
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  PrimaryGeneratedColumn,
} from 'typeorm'

import { AccessTokenEntity } from './access-token.entity'
import { generateUUID } from '~/utils'

@Entity('user_refresh_tokens')
export class RefreshTokenEntity extends BaseEntity {
  @BeforeInsert()
  beforeInsert() {
    this.id = generateUUID()
  }

  @PrimaryGeneratedColumn('uuid')
  id!: string

  @Column({ length: 500, default: '' })
  value!: string

  @Column({ comment: '令牌过期时间', nullable: true })
  expired_at!: Date

  @CreateDateColumn({ comment: '令牌创建时间' })
  created_at!: Date

  @OneToOne(() => AccessTokenEntity, (accessToken) => accessToken.refreshToken, {
    onDelete: 'CASCADE',
  })
  @JoinColumn()
  accessToken!: AccessTokenEntity
}
