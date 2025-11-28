<script setup lang="ts">
import { useChatStore } from '@/stores/chat'
import { storeToRefs } from 'pinia'
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'

import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'
import 'dayjs/locale/zh-cn'

dayjs.extend(relativeTime)
dayjs.locale('zh-cn')

const chatStore = useChatStore()
const { sessions, isSidebarCollapsed: isCollapsed } = storeToRefs(chatStore)
const { toggleSidebar } = chatStore
const router = useRouter()
const route = useRoute()

const deleteConfirmId = ref<string | null>(null)

// 加载会话列表
onMounted(() => {
  chatStore.loadSessions()
})

function handleImport() {
  // Navigate to home (Welcome Guide)
  router.push('/')
}

function formatTime(timestamp: number): string {
  return dayjs.unix(timestamp).fromNow()
}

function confirmDelete(id: string, event: Event) {
  event.stopPropagation()
  deleteConfirmId.value = id
}

async function handleDelete(id: string) {
  await chatStore.deleteSession(id)
  deleteConfirmId.value = null
}

function cancelDelete() {
  deleteConfirmId.value = null
}
</script>

<template>
  <div
    class="flex h-full flex-col border-r border-gray-200 bg-gray-50 transition-all duration-300 ease-in-out dark:border-gray-800 dark:bg-gray-900"
    :class="[isCollapsed ? 'w-20' : 'w-72']"
  >
    <!-- Top Section -->
    <div class="flex flex-col p-4">
      <!-- Header / Toggle -->
      <div class="mb-6 flex items-center" :class="[isCollapsed ? 'justify-center' : 'justify-between']">
        <div v-if="!isCollapsed" class="text-lg font-semibold text-gray-900 dark:text-white">ChatLab</div>
        <UTooltip :text="isCollapsed ? '展开侧边栏' : '收起侧边栏'" :popper="{ placement: 'right' }">
          <UButton
            icon="i-heroicons-bars-3"
            color="gray"
            variant="ghost"
            size="md"
            class="flex h-12 w-12 cursor-pointer items-center justify-center rounded-full hover:bg-gray-200/60 dark:hover:bg-gray-800"
            @click="toggleSidebar"
          />
        </UTooltip>
      </div>

      <!-- New Analysis Button -->
      <UTooltip :text="isCollapsed ? '分析新聊天' : ''" :popper="{ placement: 'right' }">
        <UButton
          :block="!isCollapsed"
          class="transition-all rounded-full hover:bg-gray-200/60 dark:hover:bg-gray-800 h-12 cursor-pointer"
          :class="[isCollapsed ? 'flex w-12 items-center justify-center px-0' : 'justify-start pl-4']"
          color="gray"
          variant="ghost"
          @click="handleImport"
        >
          <UIcon name="i-heroicons-plus" class="h-5 w-5 shrink-0" :class="[isCollapsed ? '' : 'mr-2']" />
          <span v-if="!isCollapsed" class="truncate">分析新聊天</span>
        </UButton>
      </UTooltip>
    </div>

    <!-- Session List -->
    <div class="flex-1 overflow-y-auto px-3">
      <div v-if="sessions.length === 0 && !isCollapsed" class="py-8 text-center text-sm text-gray-500">暂无记录</div>

      <div class="space-y-1">
        <div v-if="!isCollapsed && sessions.length > 0" class="mb-2 px-2 text-xs font-medium text-gray-500">
          聊天记录
        </div>

        <UTooltip
          v-for="session in sessions"
          :key="session.id"
          :text="isCollapsed ? session.name : ''"
          :popper="{ placement: 'right' }"
        >
          <div
            class="group relative flex w-full items-center rounded-full p-2 text-left transition-colors"
            :class="[
              route.params.id === session.id && !isCollapsed
                ? 'bg-primary-100 text-gray-900 dark:bg-primary-900/30 dark:text-primary-100'
                : 'text-gray-700 dark:text-gray-200 hover:bg-gray-200/60 dark:hover:bg-gray-800',
              isCollapsed ? 'justify-center cursor-pointer' : 'cursor-pointer',
            ]"
            @click="router.push({ name: 'chat', params: { id: session.id } })"
          >
            <!-- Platform Icon / Text Avatar -->
            <div
              class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold"
              :class="[
                route.params.id === session.id
                  ? 'bg-primary-600 text-white dark:bg-primary-500 dark:text-white'
                  : 'bg-gray-400 text-white dark:bg-gray-600 dark:text-white',
                isCollapsed ? '' : 'mr-3',
              ]"
            >
              {{ session.name ? session.name.charAt(0) : '?' }}
            </div>

            <!-- Session Info -->
            <div v-if="!isCollapsed" class="min-w-0 flex-1">
              <p class="truncate text-sm font-medium">
                {{ session.name }}
              </p>
              <p class="truncate text-xs text-gray-500 dark:text-gray-400">
                {{ session.messageCount }} 条消息 · {{ formatTime(session.importedAt) }}
              </p>
            </div>

            <!-- Delete Button -->
            <div v-if="!isCollapsed" class="shrink-0 opacity-0 transition-opacity group-hover:opacity-100">
              <UPopover v-if="deleteConfirmId === session.id" :open="true" @update:open="cancelDelete">
                <template #default>
                  <UButton
                    icon="i-heroicons-trash"
                    color="red"
                    variant="ghost"
                    size="xs"
                    class="flex h-8 w-8 cursor-pointer items-center justify-center rounded-full"
                    @click="(e: Event) => confirmDelete(session.id, e)"
                  />
                </template>
                <template #content>
                  <div class="p-3">
                    <p class="mb-3 text-sm">确定删除此记录？</p>
                    <div class="flex justify-end gap-2">
                      <UButton size="xs" color="red" @click="handleDelete(session.id)">确定删除</UButton>
                    </div>
                  </div>
                </template>
              </UPopover>
              <UButton
                v-else
                icon="i-heroicons-trash"
                color="gray"
                variant="ghost"
                size="xs"
                class="flex h-8 w-8 cursor-pointer items-center justify-center rounded-full"
                @click="(e: Event) => confirmDelete(session.id, e)"
              />
            </div>
          </div>
        </UTooltip>
      </div>
    </div>

    <!-- Footer -->
    <div class="border-t border-gray-200 p-4 dark:border-gray-800">
      <UTooltip :text="isCollapsed ? '设置和帮助' : ''" :popper="{ placement: 'right' }">
        <UButton
          :block="!isCollapsed"
          class="transition-all rounded-full hover:bg-gray-200/60 dark:hover:bg-gray-800 h-12 cursor-pointer"
          :class="[isCollapsed ? 'flex w-12 items-center justify-center px-0' : 'justify-start pl-4']"
          color="gray"
          variant="ghost"
        >
          <UIcon name="i-heroicons-cog-6-tooth" class="h-5 w-5 shrink-0" :class="[isCollapsed ? '' : 'mr-2']" />
          <span v-if="!isCollapsed" class="truncate">设置和帮助</span>
        </UButton>
      </UTooltip>
    </div>
  </div>
</template>
