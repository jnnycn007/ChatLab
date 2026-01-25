<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'
import { useDateFormat } from '@vueuse/core'

const props = defineProps<{
  open: boolean
  sessionId: string
}>()

const emit = defineEmits<{
  'update:open': [value: boolean]
  'completed': []
}>()

const { t, locale } = useI18n()

// 计算属性：双向绑定 open
const isOpen = computed({
  get: () => props.open,
  set: (val) => emit('update:open', val),
})

// 查询模式：按时间 / 按数量
type QueryMode = 'time' | 'count'
const queryMode = ref<QueryMode>('count')

// 按数量选项
type CountPreset = 50 | 100 | 200 | 500
const selectedCount = ref<CountPreset>(100)

// 时间范围选项
type TimeRangePreset = 'today' | 'yesterday' | 'week' | 'month' | 'custom'
const selectedPreset = ref<TimeRangePreset>('today')

// 自定义时间范围
const customStartDate = ref<Date | null>(null)
const customEndDate = ref<Date | null>(null)

// 会话列表
interface SessionItem {
  id: number
  startTs: number
  endTs: number
  messageCount: number
  summary: string | null
}
const sessions = ref<SessionItem[]>([])
const isLoading = ref(false)

// 生成状态
const isGenerating = ref(false)
const currentIndex = ref(0)
const totalToGenerate = ref(0) // 记录开始时的总数
const results = ref<Array<{ id: number; status: 'success' | 'failed' | 'skipped'; message?: string }>>([])
const shouldStop = ref(false)

// 滚动容器引用
const resultsContainer = ref<HTMLElement | null>(null)

// 计算时间范围
const timeRange = computed(() => {
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())

  switch (selectedPreset.value) {
    case 'today':
      return {
        start: today.getTime(),
        end: now.getTime(),
      }
    case 'yesterday': {
      const yesterday = new Date(today)
      yesterday.setDate(yesterday.getDate() - 1)
      return {
        start: yesterday.getTime(),
        end: today.getTime() - 1,
      }
    }
    case 'week': {
      const weekAgo = new Date(today)
      weekAgo.setDate(weekAgo.getDate() - 7)
      return {
        start: weekAgo.getTime(),
        end: now.getTime(),
      }
    }
    case 'month': {
      const monthAgo = new Date(today)
      monthAgo.setMonth(monthAgo.getMonth() - 1)
      return {
        start: monthAgo.getTime(),
        end: now.getTime(),
      }
    }
    case 'custom':
      if (customStartDate.value && customEndDate.value) {
        return {
          start: customStartDate.value.getTime(),
          end: new Date(customEndDate.value.getTime() + 24 * 60 * 60 * 1000 - 1).getTime(), // 当天结束
        }
      }
      return null
    default:
      return null
  }
})

// 待生成的会话（排除已有摘要的）
const pendingSessions = computed(() => {
  return sessions.value.filter((s) => !s.summary)
})

// 已有摘要的会话数
const existingSummaryCount = computed(() => {
  return sessions.value.filter((s) => s.summary).length
})

// 进度百分比
const progressPercent = computed(() => {
  if (totalToGenerate.value === 0) return 100
  return Math.round((currentIndex.value / totalToGenerate.value) * 100)
})

// 统计结果
const stats = computed(() => {
  const success = results.value.filter((r) => r.status === 'success').length
  const failed = results.value.filter((r) => r.status === 'failed').length
  const skipped = results.value.filter((r) => r.status === 'skipped').length
  return { success, failed, skipped }
})

// 查询会话
async function fetchSessions() {
  isLoading.value = true
  try {
    if (queryMode.value === 'count') {
      // 按数量查询
      sessions.value = await window.sessionApi.getRecent(props.sessionId, selectedCount.value)
    } else {
      // 按时间查询
      if (!timeRange.value) {
        sessions.value = []
        return
      }
      // 将时间戳转换为秒（数据库中使用秒）
      const startTs = Math.floor(timeRange.value.start / 1000)
      const endTs = Math.floor(timeRange.value.end / 1000)

      sessions.value = await window.sessionApi.getByTimeRange(props.sessionId, startTs, endTs)
    }
  } catch (error) {
    console.error('查询会话失败:', error)
    sessions.value = []
  } finally {
    isLoading.value = false
  }
}

// 监听查询条件变化
watch(
  () => [queryMode.value, selectedCount.value, selectedPreset.value, customStartDate.value, customEndDate.value],
  () => {
    if (queryMode.value === 'count') {
      fetchSessions()
    } else if (selectedPreset.value !== 'custom' || (customStartDate.value && customEndDate.value)) {
      fetchSessions()
    }
  },
  { immediate: true }
)

// 监听弹窗打开
watch(
  () => props.open,
  (isOpen) => {
    if (isOpen) {
      // 重置状态
      isGenerating.value = false
      currentIndex.value = 0
      results.value = []
      shouldStop.value = false
      fetchSessions()
    }
  }
)

// 开始生成
async function startGenerate() {
  // 复制一份静态数组，避免在循环中因 computed 值变化导致问题
  const sessionsToProcess = [...pendingSessions.value]
  if (sessionsToProcess.length === 0) return

  isGenerating.value = true
  shouldStop.value = false
  currentIndex.value = 0
  totalToGenerate.value = sessionsToProcess.length
  results.value = []

  for (const session of sessionsToProcess) {
    if (shouldStop.value) break

    try {
      const result = await window.sessionApi.generateSummary(
        props.sessionId,
        session.id,
        locale.value,
        false
      )

      if (result.success) {
        results.value.push({ id: session.id, status: 'success' })
        // 更新本地会话数据
        const idx = sessions.value.findIndex((s) => s.id === session.id)
        if (idx !== -1) {
          sessions.value[idx].summary = result.summary || ''
        }
      } else {
        results.value.push({ id: session.id, status: 'failed', message: result.error })
      }
    } catch (error) {
      results.value.push({ id: session.id, status: 'failed', message: String(error) })
    }

    currentIndex.value++

    // 自动滚动到底部
    await nextTick()
    if (resultsContainer.value) {
      resultsContainer.value.scrollTop = resultsContainer.value.scrollHeight
    }
  }

  isGenerating.value = false

  // 如果有成功生成的，通知父组件刷新
  if (stats.value.success > 0) {
    emit('completed')
  }
}

// 停止生成
function stopGenerate() {
  shouldStop.value = true
}

// 关闭弹窗
function close() {
  if (isGenerating.value) {
    shouldStop.value = true
  }
  emit('update:open', false)
}

// 格式化时间戳
function formatTs(ts: number) {
  return useDateFormat(new Date(ts * 1000), 'MM-DD HH:mm').value
}
</script>

<template>
  <UModal v-model:open="isOpen" :ui="{ overlay: 'z-[10001]', content: 'z-[10001]' }">
    <template #content>
      <UCard>
        <template #header>
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold">{{ t('chatRecord.batchSummary.title', '批量生成摘要') }}</h3>
          <UButton
            color="neutral"
            variant="ghost"
            icon="i-heroicons-x-mark"
            size="sm"
            @click="close"
          />
        </div>
      </template>

      <div class="space-y-4">
        <!-- 查询模式切换 -->
        <div class="flex gap-2 border-b border-gray-200 dark:border-gray-700 pb-3">
          <UButton
            :color="queryMode === 'count' ? 'primary' : 'neutral'"
            :variant="queryMode === 'count' ? 'solid' : 'ghost'"
            size="sm"
            @click="queryMode = 'count'"
            :disabled="isGenerating"
          >
            {{ t('chatRecord.batchSummary.byCount', '按数量') }}
          </UButton>
          <UButton
            :color="queryMode === 'time' ? 'primary' : 'neutral'"
            :variant="queryMode === 'time' ? 'solid' : 'ghost'"
            size="sm"
            @click="queryMode = 'time'"
            :disabled="isGenerating"
          >
            {{ t('chatRecord.batchSummary.byTime', '按时间') }}
          </UButton>
        </div>

        <!-- 按数量选择 -->
        <div v-if="queryMode === 'count'">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            {{ t('chatRecord.batchSummary.selectCount', '选择数量') }}
          </label>
          <div class="flex flex-wrap gap-2">
            <UButton
              v-for="count in [50, 100, 200, 500]"
              :key="count"
              :color="selectedCount === count ? 'primary' : 'neutral'"
              :variant="selectedCount === count ? 'solid' : 'outline'"
              size="sm"
              @click="selectedCount = count as CountPreset"
              :disabled="isGenerating"
            >
              {{ t('chatRecord.batchSummary.recent', '最近') }} {{ count }} {{ t('chatRecord.batchSummary.sessions', '次') }}
            </UButton>
          </div>
        </div>

        <!-- 按时间范围选择 -->
        <div v-else>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            {{ t('chatRecord.batchSummary.timeRange', '选择时间范围') }}
          </label>
          <div class="flex flex-wrap gap-2">
            <UButton
              v-for="preset in [
                { key: 'today', label: t('chatRecord.batchSummary.today', '今天') },
                { key: 'yesterday', label: t('chatRecord.batchSummary.yesterday', '昨天') },
                { key: 'week', label: t('chatRecord.batchSummary.week', '最近7天') },
                { key: 'month', label: t('chatRecord.batchSummary.month', '最近30天') },
                { key: 'custom', label: t('chatRecord.batchSummary.custom', '自定义') },
              ]"
              :key="preset.key"
              :color="selectedPreset === preset.key ? 'primary' : 'neutral'"
              :variant="selectedPreset === preset.key ? 'solid' : 'outline'"
              size="sm"
              @click="selectedPreset = preset.key as TimeRangePreset"
              :disabled="isGenerating"
            >
              {{ preset.label }}
            </UButton>
          </div>

          <!-- 自定义日期选择 -->
          <div v-if="selectedPreset === 'custom'" class="mt-3 flex items-center gap-2">
            <UInput
              type="date"
              v-model="customStartDate"
              :disabled="isGenerating"
              size="sm"
            />
            <span class="text-gray-500">—</span>
            <UInput
              type="date"
              v-model="customEndDate"
              :disabled="isGenerating"
              size="sm"
            />
          </div>
        </div>

        <!-- 会话预览 -->
        <div v-if="!isLoading" class="text-sm text-gray-600 dark:text-gray-400">
          <template v-if="sessions.length > 0">
            <p>
              {{ t('chatRecord.batchSummary.found', '找到') }} {{ sessions.length }} {{ t('chatRecord.batchSummary.sessionsUnit', '个会话') }}
              <template v-if="existingSummaryCount > 0">
                <span class="text-green-600 dark:text-green-400">
                  （{{ existingSummaryCount }} {{ t('chatRecord.batchSummary.existingSkip', '个已有摘要将跳过') }}）
                </span>
              </template>
            </p>
            <p v-if="pendingSessions.length > 0" class="mt-1">
              {{ t('chatRecord.batchSummary.pending', '待生成:') }} {{ pendingSessions.length }} {{ t('chatRecord.batchSummary.unit', '个') }}
            </p>
          </template>
          <p v-else class="text-gray-400">
            {{ t('chatRecord.batchSummary.noSessions', '该时间范围内没有会话') }}
          </p>
        </div>
        <div v-else class="flex items-center gap-2 text-sm text-gray-500">
          <UIcon name="i-heroicons-arrow-path" class="animate-spin" />
          {{ t('chatRecord.batchSummary.loading', '加载中...') }}
        </div>

        <!-- 进度条 -->
        <div v-if="isGenerating || results.length > 0" class="space-y-2">
          <div class="flex items-center justify-between text-sm">
            <span>{{ t('chatRecord.batchSummary.progress', '进度') }}</span>
            <span>{{ currentIndex }} / {{ totalToGenerate || pendingSessions.length }}</span>
          </div>
          <UProgress :value="progressPercent" />
        </div>

        <!-- 结果列表 -->
        <div
          v-if="results.length > 0"
          ref="resultsContainer"
          class="max-h-48 overflow-y-auto rounded border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50"
        >
          <div
            v-for="result in results"
            :key="result.id"
            class="flex items-center gap-2 px-3 py-2 text-sm border-b border-gray-200 dark:border-gray-700 last:border-b-0"
          >
            <UIcon
              :name="result.status === 'success' ? 'i-heroicons-check-circle' : result.status === 'skipped' ? 'i-heroicons-minus-circle' : 'i-heroicons-x-circle'"
              :class="{
                'text-green-500': result.status === 'success',
                'text-gray-400': result.status === 'skipped',
                'text-red-500': result.status === 'failed',
              }"
            />
            <span class="flex-1">
              {{ t('chatRecord.batchSummary.session', '会话') }} #{{ result.id }}
              <span v-if="result.status === 'failed' && result.message" class="text-red-500 text-xs ml-1">
                ({{ result.message }})
              </span>
            </span>
            <span
              :class="{
                'text-green-600 dark:text-green-400': result.status === 'success',
                'text-gray-500': result.status === 'skipped',
                'text-red-600 dark:text-red-400': result.status === 'failed',
              }"
            >
              {{
                result.status === 'success'
                  ? t('chatRecord.batchSummary.statusSuccess', '成功')
                  : result.status === 'skipped'
                    ? t('chatRecord.batchSummary.statusSkipped', '跳过')
                    : t('chatRecord.batchSummary.statusFailed', '失败')
              }}
            </span>
          </div>
        </div>

        <!-- 统计结果 -->
        <div v-if="!isGenerating && results.length > 0" class="flex items-center gap-4 text-sm">
          <span class="text-green-600 dark:text-green-400">
            <UIcon name="i-heroicons-check-circle" class="mr-1" />
            {{ t('chatRecord.batchSummary.success', '成功:') }} {{ stats.success }}
          </span>
          <span v-if="stats.failed > 0" class="text-red-600 dark:text-red-400">
            <UIcon name="i-heroicons-x-circle" class="mr-1" />
            {{ t('chatRecord.batchSummary.failed', '失败:') }} {{ stats.failed }}
          </span>
          <span v-if="stats.skipped > 0" class="text-gray-500">
            <UIcon name="i-heroicons-minus-circle" class="mr-1" />
            {{ t('chatRecord.batchSummary.skipped', '跳过:') }} {{ stats.skipped }}
          </span>
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton
            color="neutral"
            variant="outline"
            @click="close"
            :disabled="isGenerating"
          >
            {{ t('common.close', '关闭') }}
          </UButton>
          <UButton
            v-if="!isGenerating"
            color="primary"
            @click="startGenerate"
            :disabled="pendingSessions.length === 0 || isLoading"
          >
            {{ t('chatRecord.batchSummary.start', '开始生成') }}
          </UButton>
          <UButton
            v-else
            color="error"
            @click="stopGenerate"
          >
            {{ t('chatRecord.batchSummary.stop', '停止') }}
          </UButton>
        </div>
        </template>
      </UCard>
    </template>
  </UModal>
</template>

