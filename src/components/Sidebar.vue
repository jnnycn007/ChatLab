<script setup lang="ts">
import { useChatStore } from '@/stores/chat'
import { storeToRefs } from 'pinia'
import { ref } from 'vue'

const chatStore = useChatStore()
const { sessions, currentSessionId } = storeToRefs(chatStore)

const isCollapsed = ref(false)

function toggleSidebar() {
  isCollapsed.value = !isCollapsed.value
}

function handleImport() {
  // TODO: Implement import logic
  console.log('Import clicked')
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
        <div v-if="!isCollapsed" class="text-lg font-semibold text-gray-900 dark:text-white">
          ChatLens
        </div>
        <UButton
          icon="i-heroicons-bars-3"
          color="gray"
          variant="ghost"
          size="sm"
          @click="toggleSidebar"
        />
      </div>

      <!-- New Analysis Button -->
      <UTooltip :text="isCollapsed ? '新建分析' : ''" :popper="{ placement: 'right' }">
        <UButton
          block
          class="transition-all"
          :class="[isCollapsed ? 'px-0' : '']"
          color="gray"
          variant="solid"
          :icon="isCollapsed ? 'i-heroicons-plus' : 'i-heroicons-plus'"
          :label="isCollapsed ? '' : '新建分析'"
          @click="handleImport"
        />
      </UTooltip>
    </div>

    <!-- Session List -->
    <div class="flex-1 overflow-y-auto px-3">
      <div v-if="sessions.length === 0 && !isCollapsed" class="py-8 text-center text-sm text-gray-500">
        暂无记录
      </div>

      <div class="space-y-1">
        <div v-if="!isCollapsed && sessions.length > 0" class="mb-2 px-2 text-xs font-medium text-gray-500">
          最近
        </div>

        <button
          v-for="session in sessions"
          :key="session.id"
          class="flex w-full items-center rounded-full p-2 text-left transition-colors hover:bg-gray-200 dark:hover:bg-gray-800"
          :class="[
            currentSessionId === session.id ? 'bg-primary-100 text-primary-900 dark:bg-primary-900/30 dark:text-primary-100' : 'text-gray-700 dark:text-gray-200',
            isCollapsed ? 'justify-center' : ''
          ]"
          @click="chatStore.selectSession(session.id)"
        >
          <UAvatar
            :src="session.avatar"
            :alt="session.name"
            size="sm"
            :class="[isCollapsed ? '' : 'mr-3']"
          />

          <div v-if="!isCollapsed" class="min-w-0 flex-1">
            <p class="truncate text-sm font-medium">
              {{ session.name }}
            </p>
          </div>
        </button>
      </div>
    </div>

    <!-- Footer (Optional settings or help) -->
    <div class="border-t border-gray-200 p-4 dark:border-gray-800">
       <UTooltip :text="isCollapsed ? '设置' : ''" :popper="{ placement: 'right' }">
        <UButton
          block
          color="gray"
          variant="ghost"
          icon="i-heroicons-cog-6-tooth"
          :label="isCollapsed ? '' : '设置'"
          :class="[isCollapsed ? 'px-0' : 'justify-start']"
        />
       </UTooltip>
    </div>
  </div>
</template>
